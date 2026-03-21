import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../providers/qr_provider.dart';

/// Определяем, нужна ли камера (только мобилки).
bool get _useCameraScanner {
  if (kIsWeb) return false;
  // На десктопе mobile_scanner тоже не работает корректно
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}

class ScannerPage extends ConsumerStatefulWidget {
  const ScannerPage({super.key});

  @override
  ConsumerState<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends ConsumerState<ScannerPage> {
  // ─── Камера (мобилки) ─────────────────────────────────────────────────
  MobileScannerController? _ctrl;
  bool _processing = false;
  Timer? _dismissTimer;

  // ─── Текстовое поле (веб / десктоп) ──────────────────────────────────
  final _textController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (_useCameraScanner) {
      _ctrl = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _dismissTimer?.cancel();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── Камера: обнаружен QR ──────────────────────────────────────────────
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing) return;
    final token = capture.barcodes.firstOrNull?.rawValue;
    if (token == null) return;

    _processing = true;
    await _ctrl?.stop();
    await _validateToken(token);
  }

  // ── Текстовое поле: сканер записал значение ───────────────────────────
  void _onFieldSubmitted(String value) {
    final token = value.trim();
    if (token.isEmpty) return;
    _textController.clear();
    _validateToken(token);
  }

  // ── Общий метод валидации ─────────────────────────────────────────────
  Future<void> _validateToken(String token) async {
    await ref.read(scannerProvider.notifier).validate(token);

    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) _resetScan();
    });
  }

  void _resetScan() {
    ref.read(scannerProvider.notifier).reset();
    _processing = false;
    _ctrl?.start();
    // На вебе/десктопе возвращаем фокус в поле
    if (!_useCameraScanner) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scan = ref.watch(scannerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Сканер QR'),
        actions: [
          if (_useCameraScanner)
            IconButton(
              icon: const Icon(Icons.flash_on_rounded),
              onPressed: () => _ctrl?.toggleTorch(),
            ),
        ],
      ),
      body: _useCameraScanner
          ? _buildCameraBody(scan)
          : _buildTextFieldBody(scan),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Камера (Android / iOS)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildCameraBody(ScannerState scan) {
    return Stack(
      children: [
        MobileScanner(controller: _ctrl!, onDetect: _onDetect),

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

        if (scan.isLoading)
          const ColoredBox(
            color: Colors.black54,
            child: Center(child: CircularProgressIndicator()),
          ),

        if (scan.result != null)
          _ResultOverlay(result: scan.result!, onDismiss: _resetScan),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // Текстовое поле (Web / Desktop)
  // ═════════════════════════════════════════════════════════════════════════
  Widget _buildTextFieldBody(ScannerState scan) {
    // Автофокус — сканер сразу пишет в поле
    if (scan.result == null && !scan.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.qr_code_scanner_rounded,
                size: 80,
                color: Theme.of(context).colorScheme.primary.withAlpha(180),
              ),
              const SizedBox(height: 24),
              Text(
                'Отсканируйте QR-код',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Наведите сканер на QR-код —\nзначение появится в поле ниже и отправится автоматически',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 32),

              // Поле ввода
              TextField(
                controller: _textController,
                focusNode: _focusNode,
                autofocus: true,
                onSubmitted: _onFieldSubmitted,
                enabled: !scan.isLoading && scan.result == null,
                decoration: InputDecoration(
                  labelText: 'QR-код',
                  hintText: 'Значение появится автоматически...',
                  prefixIcon: const Icon(Icons.qr_code),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Отправить',
                    onPressed: scan.isLoading
                        ? null
                        : () => _onFieldSubmitted(_textController.text),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Загрузка
              if (scan.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: CircularProgressIndicator(),
                ),

              // Результат
              if (scan.result != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _DesktopResultCard(
                    result: scan.result!,
                    onDismiss: _resetScan,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Виджет результата — Desktop / Web (карточка)
// ═══════════════════════════════════════════════════════════════════════════════
class _DesktopResultCard extends StatelessWidget {
  const _DesktopResultCard({required this.result, required this.onDismiss});

  final ValidateResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final granted = result.isGranted;

    return Card(
      color: granted ? const Color(0xFFE8F8EE) : const Color(0xFFFDE8E8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: granted ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C),
              size: 56,
            ),
            const SizedBox(height: 12),
            Text(
              granted ? 'Доступ разрешён' : 'Доступ запрещён',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: granted ? const Color(0xFF1A6B3C) : const Color(0xFF9B1C1C),
              ),
            ),
            if (result.user != null) ...[
              const SizedBox(height: 8),
              Text(result.user!.fullName,
                  style: TextStyle(fontSize: 16, color: granted ? const Color(0xFF1A5C32) : const Color(0xFF7A1A1A))),
            ],
            if (result.detail != null) ...[
              const SizedBox(height: 8),
              Text(result.detail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: granted ? const Color(0xFF3D7A55) : const Color(0xFF8A3030))),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: onDismiss,
              child: const Text('Сканировать ещё'),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Виджет результата — мобилка (полноэкранный оверлей)
// ═══════════════════════════════════════════════════════════════════════════════
class _ResultOverlay extends StatelessWidget {
  const _ResultOverlay({required this.result, required this.onDismiss});

  final ValidateResult result;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final granted = result.isGranted;
    final bgColor =
        granted ? const Color(0xFF2ECC71).withAlpha(220) : const Color(0xFFE74C3C).withAlpha(220);

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
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
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
                  child:
                      const Text('Закрыть', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
