import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/network/sse_service.dart';
import '../../core/utils/brightness_helper.dart';
import '../../core/utils/screen_protection.dart';
import '../../core/utils/snackbar_utils.dart';
import '../providers/brightness_provider.dart';
import '../providers/qr_provider.dart';

/// Виджет QR-пропуска, который сразу показывает QR-код
/// с круговым таймером обратного отсчёта, защитой от скриншотов
/// и кнопкой обновления.
class QrPassWidget extends ConsumerStatefulWidget {
  const QrPassWidget({super.key});

  @override
  ConsumerState<QrPassWidget> createState() => _QrPassWidgetState();
}

class _QrPassWidgetState extends ConsumerState<QrPassWidget> {
  double _prevBrightness = 0.5;
  static const _totalSeconds = 300;

  @override
  void initState() {
    super.initState();
    enableScreenProtection();
    _initBrightness();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(qrProvider.notifier).generate(forceNew: true);
      HapticFeedback.heavyImpact();
    });
  }

  Future<void> _initBrightness() async {
    final enabled = ref.read(qrBrightnessEnabledProvider);
    if (enabled) {
      _prevBrightness = await setMaxBrightness();
    }
  }

  @override
  void dispose() {
    disableScreenProtection();
    final enabled = ref.read(qrBrightnessEnabledProvider);
    if (enabled) {
      restoreBrightness(_prevBrightness);
    }
    super.dispose();
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(qrProvider.notifier).generate(forceNew: true);
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    final qr = ref.watch(qrProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final containerBg = isDark ? primary.withAlpha(30) : primary.withAlpha(18);
    final borderClr = primary.withAlpha(isDark ? 60 : 50);

    // ── Listen to real-time attendance events via SSE ────────────────
    ref.listen<AsyncValue<AttendanceEvent>>(attendanceEventProvider,
        (prev, next) {
      next.whenData((event) {
        HapticFeedback.heavyImpact();
        // Auto-regenerate QR (the old one was just used)
        ref.read(qrProvider.notifier).generate(forceNew: true);
        // Show notification
        if (!context.mounted) return;
        if (event.isEntry) {
          final time = _formatIso(event.enteredAt);
          showSuccessSnack(context, 'Вход зафиксирован в $time');
        } else {
          final worked = _formatWorkedSeconds(event.workedSeconds);
          showSuccessSnack(context, 'Выход зафиксирован. Отработано: $worked');
        }
      });
    });

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderClr),
      ),
      child: Column(
        children: [
          // Заголовок
          Row(
            children: [
              Icon(Icons.qr_code_rounded, color: primary, size: 24),
              const SizedBox(width: 10),
              Text(
                'Ваш QR-пропуск',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Контент: загрузка / ошибка / QR ────────────────────
          if (qr.isLoading)
            const SizedBox(
              height: 240,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (qr.error != null)
            _ErrorCard(error: qr.error!, onRetry: _refresh)
          else if (qr.qrToken != null) ...[
            // QR-код внутри кругового таймера
            _CircularTimerWithQr(
              token: qr.qrToken!.token,
              secondsLeft: qr.secondsLeft,
              totalSeconds: _totalSeconds,
            ),
            const SizedBox(height: 12),
            Text(
              'QR обновится автоматически',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 16),

            // Кнопка обновить
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: qr.isLoading ? null : _refresh,
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Обновить QR'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Круговой таймер с QR-кодом внутри ──────────────────────────────────────

class _CircularTimerWithQr extends StatelessWidget {
  const _CircularTimerWithQr({
    required this.token,
    required this.secondsLeft,
    required this.totalSeconds,
  });

  final String token;
  final int secondsLeft;
  final int totalSeconds;

  String _format() {
    final m = secondsLeft ~/ 60;
    final s = secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    final fraction =
        totalSeconds > 0 ? (secondsLeft / totalSeconds).clamp(0.0, 1.0) : 0.0;
    if (fraction > 0.5) return Colors.green;
    if (fraction > 0.2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final fraction =
        totalSeconds > 0 ? (secondsLeft / totalSeconds).clamp(0.0, 1.0) : 0.0;
    final color = _timerColor();
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          width: 300,
          height: 300,
          child: CustomPaint(
            painter: _CircularTimerPainter(
              fraction: fraction,
              color: color,
              trackColor: color.withAlpha(35),
              strokeWidth: 8,
            ),
            child: Center(
              // Вписываем QR в круг: диаметр внутреннего круга 270px,
              // сторона вписанного квадрата = 270/√2 ≈ 190.9,
              // минус отступы 12×2 = 24 → QR ~167px — полностью внутри круга
              child: ClipOval(
                child: Container(
                  width: 270,
                  height: 270,
                  color: Colors.white,
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: (270 / math.sqrt(2)) - 24,
                    height: (270 / math.sqrt(2)) - 24,
                    child: QrImageView(
                      data: token,
                      version: QrVersions.auto,
                      backgroundColor: Colors.white,
                      errorStateBuilder: (_, __) => const Icon(
                        Icons.error,
                        size: 60,
                        color: Colors.red,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Текст обратного отсчёта
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.timer_outlined, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              _format(),
              style: theme.textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ─── CustomPainter для кругового прогресса ──────────────────────────────────

class _CircularTimerPainter extends CustomPainter {
  _CircularTimerPainter({
    required this.fraction,
    required this.color,
    required this.trackColor,
    required this.strokeWidth,
  });

  final double fraction;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) / 2) - strokeWidth / 2;

    // Фоновая дорожка
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Прогресс
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * fraction;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // начало — сверху
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularTimerPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.color != color;
}

// ─── Error card ─────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 180,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Повторить'),
          ),
        ],
      ),
    );
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _formatIso(String? iso) {
  if (iso == null) return '—';
  try {
    final dt = DateTime.parse(iso).toLocal();
    return DateFormat('HH:mm').format(dt);
  } catch (_) {
    return '—';
  }
}

String _formatWorkedSeconds(int? seconds) {
  if (seconds == null || seconds <= 0) return '—';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}ч ${m}мин';
  return '${m}мин';
}
