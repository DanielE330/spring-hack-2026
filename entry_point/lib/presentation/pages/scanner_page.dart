import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/qr_provider.dart';

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  final MobileScannerController _ctrl = MobileScannerController();
  bool _processing = false;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _ctrl.dispose();
    _dismissTimer?.cancel();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null) return;

    _processing = true;
    await _ctrl.stop();
    await ref.read(scannerProvider.notifier).validate(token);

    // Auto dismiss after 3 s
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        ref.read(scannerProvider.notifier).reset();
        _processing = false;
        _ctrl.start();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер QR'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: _ctrl.toggleTorch,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Camera view
          MobileScanner(controller: _ctrl, onDetect: _onDetect),

          // Scanning frame hint
          if (scan.result == null && !scan.isLoading)
            Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

          // Loading overlay
          if (scan.isLoading)
            const ColoredBox(
              color: Colors.black54,
              child: Center(child: CircularProgressIndicator()),
            ),

          // Result overlay
          if (scan.result != null)
            _ResultOverlay(
              result: scan.result!,
              onDismiss: () {
                _dismissTimer?.cancel();
                ref.read(scannerProvider.notifier).reset();
                _processing = false;
                _ctrl.start();
              },
            ),
        ],
      ),
    );
  }
}

class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.result, required this.onDismiss});

  final ValidateResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final granted = result.isGranted;
    final bgColor = granted
        ? Colors.green.withAlpha(220)
        : Colors.red.withAlpha(220);

    return GestureDetector(
      onTap: onDismiss,
      child: ColoredBox(
        color: bgColor,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: Colors.white,
                  size: 96,
                ),
                const SizedBox(height: 16),
                Text(
                  granted ? 'Доступ разрешён' : 'Доступ запрещён',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (result.user != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.user!.fullName,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 18),
                  ),
                ],
                if (result.detail != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    result.detail!,
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                TextButton(
                  onPressed: onDismiss,
                  child: const Text('Закрыть',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
