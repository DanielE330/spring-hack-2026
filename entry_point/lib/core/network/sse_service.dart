import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/api_constants.dart';
import '../storage/secure_storage.dart';
import '../utils/app_logger.dart';

// ─── AttendanceEvent ────────────────────────────────────────────────────────

/// Real-time event pushed from the server when an admin scans the user's QR.
class AttendanceEvent {
  const AttendanceEvent({
    required this.attendanceEvent,
    this.enteredAt,
    this.exitedAt,
    this.workedSeconds,
  });

  final String attendanceEvent; // 'entry' | 'exit'
  final String? enteredAt;
  final String? exitedAt;
  final int? workedSeconds;

  bool get isEntry => attendanceEvent == 'entry';
  bool get isExit => attendanceEvent == 'exit';

  factory AttendanceEvent.fromJson(Map<String, dynamic> json) {
    return AttendanceEvent(
      attendanceEvent: json['attendance_event'] as String? ?? 'entry',
      enteredAt: json['entered_at'] as String?,
      exitedAt: json['exited_at'] as String?,
      workedSeconds: json['worked_seconds'] as int?,
    );
  }
}

// ─── Provider ───────────────────────────────────────────────────────────────

/// Streams [AttendanceEvent]s via SSE from the backend.
///
/// Connects when first watched (e.g., by [QrPassWidget]) and
/// auto-disconnects when all listeners are gone (autoDispose).
/// Reconnects with exponential backoff on errors.
final attendanceEventProvider =
    StreamProvider.autoDispose<AttendanceEvent>((ref) {
  const tag = 'SSE';
  final controller = StreamController<AttendanceEvent>();
  HttpClient? httpClient;
  bool disposed = false;

  ref.onDispose(() {
    disposed = true;
    httpClient?.close(force: true);
    controller.close();
    AppLogger.i(tag, 'Provider disposed — connection closed');
  });

  () async {
    final deviceCode = await SecureStorage.instance.getDeviceCode();
    if (deviceCode == null || disposed) {
      AppLogger.w(tag, 'No device code — SSE skipped');
      return;
    }

    final url = Uri.parse(
      '${ApiConstants.baseUrl}${ApiConstants.userEvents}',
    );

    int retryDelay = 2;
    const maxRetry = 30;

    while (!disposed) {
      try {
        httpClient = HttpClient();
        httpClient!.connectionTimeout = const Duration(seconds: 10);

        AppLogger.i(tag, 'Connecting to $url');
        final request = await httpClient!.getUrl(url);
        request.headers.set('Authorization', 'Token $deviceCode');
        request.headers.set('Accept', 'text/event-stream');
        request.headers.set('Cache-Control', 'no-cache');

        final response = await request.close();

        if (response.statusCode != 200) {
          AppLogger.w(tag, 'HTTP ${response.statusCode}');
          await response.drain<void>();
          throw HttpException('SSE HTTP ${response.statusCode}');
        }

        AppLogger.i(tag, 'Connected ✅');
        retryDelay = 2; // reset on success

        String buffer = '';
        await for (final bytes in response) {
          if (disposed) break;
          buffer += utf8.decode(bytes);

          // SSE events are delimited by double newlines
          while (buffer.contains('\n\n')) {
            final idx = buffer.indexOf('\n\n');
            final rawEvent = buffer.substring(0, idx);
            buffer = buffer.substring(idx + 2);

            final event = _parseSSE(rawEvent);
            if (event != null && !controller.isClosed) {
              controller.add(event);
            }
          }
        }

        AppLogger.w(tag, 'Stream ended — will reconnect');
      } catch (e) {
        if (disposed) break;
        AppLogger.w(tag, 'Error: $e');
      }

      if (!disposed) {
        AppLogger.i(tag, 'Reconnecting in ${retryDelay}s…');
        await Future.delayed(Duration(seconds: retryDelay));
        retryDelay = (retryDelay * 2).clamp(2, maxRetry);
      }
    }
  }();

  return controller.stream;
});

// ─── SSE parser ─────────────────────────────────────────────────────────────

/// Parses a single SSE event block into an [AttendanceEvent] (or `null`).
///
/// Expected format:
/// ```
/// data: {"event":"qr_scanned","attendance_event":"entry","entered_at":"..."}
/// ```
/// Lines starting with `:` are comments (heartbeats) and are ignored.
AttendanceEvent? _parseSSE(String rawEvent) {
  String? data;

  for (final line in rawEvent.split('\n')) {
    if (line.startsWith('data: ')) {
      data = line.substring(6);
    }
    // lines starting with ":" or "event:" are ignored
  }

  if (data == null) return null;

  try {
    final json = jsonDecode(data) as Map<String, dynamic>;
    if (json.containsKey('attendance_event')) {
      return AttendanceEvent.fromJson(json);
    }
  } catch (_) {
    // malformed JSON — skip
  }
  return null;
}
