import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
    _dismissTimer = Timer(const Duration(seconds: 5), () {
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

// Форматирование отработанного времени
String _formatWorked(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}ч ${m}мин';
  return '${m}мин';
}

String _formatTime(DateTime? dt) {
  if (dt == null) return '';
  return DateFormat('HH:mm').format(dt.toLocal());
}

// Виджет информации о пользователе (общий для обоих лейаутов)
class _UserInfoContent extends StatelessWidget {
  const _UserInfoContent({
    required this.result,
    required this.textColor,
    required this.subtextColor,
    required this.iconBgColor,
    required this.accentColor,
    this.avatarRadius = 36,
  });

  final ValidateResult result;
  final Color textColor;
  final Color subtextColor;
  final Color iconBgColor;
  final Color accentColor;
  final double avatarRadius;

  @override
  Widget build(BuildContext context) {
    final user = result.user;
    final isEntry = result.isEntry;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Статус вход/выход
        if (result.attendanceEvent != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isEntry ? Icons.login_rounded : Icons.logout_rounded,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isEntry ? 'ВХОД' : 'ВЫХОД',
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Аватар
        if (user != null) ...[
          CircleAvatar(
            radius: avatarRadius,
            backgroundColor: iconBgColor,
            backgroundImage: user.avatarUrl != null
                ? NetworkImage(user.avatarUrl!)
                : null,
            child: user.avatarUrl == null
                ? Text(
                    user.initials,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: avatarRadius * 0.7,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),

          // ФИО
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),

          // Email
          Text(
            user.email,
            style: TextStyle(color: subtextColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
        ],

        // Время входа/выхода
        if (result.enteredAt != null)
          _InfoChip(
            icon: Icons.access_time_rounded,
            label: isEntry
                ? 'Время входа: ${_formatTime(result.enteredAt)}'
                : 'Вошёл в ${_formatTime(result.enteredAt)}',
            textColor: subtextColor,
            iconColor: accentColor,
          ),
        if (result.exitedAt != null)
          _InfoChip(
            icon: Icons.access_time_rounded,
            label: 'Вышел в ${_formatTime(result.exitedAt)}',
            textColor: subtextColor,
            iconColor: accentColor,
          ),
        if (result.workedSeconds != null && result.workedSeconds! > 0)
          _InfoChip(
            icon: Icons.timer_outlined,
            label: 'Отработано: ${_formatWorked(result.workedSeconds!)}',
            textColor: subtextColor,
            iconColor: accentColor,
          ),

        // Доп. деталь (ошибка и т.п.)
        if (result.detail != null && user == null) ...[
          const SizedBox(height: 8),
          Text(
            result.detail!,
            textAlign: TextAlign.center,
            style: TextStyle(color: subtextColor),
          ),
        ],
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final Color textColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: textColor, fontSize: 13)),
        ],
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
    final bg = granted ? const Color(0xFFE8F8EE) : const Color(0xFFFDE8E8);
    final accent = granted ? const Color(0xFF2ECC71) : const Color(0xFFE74C3C);
    final text = granted ? const Color(0xFF1A6B3C) : const Color(0xFF9B1C1C);
    final subtext = granted ? const Color(0xFF3D7A55) : const Color(0xFF8A3030);
    final iconBg = granted ? const Color(0xFFC8EDDA) : const Color(0xFFF8D0D0);

    return Card(
      color: bg,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
              color: accent,
              size: 48,
            ),
            const SizedBox(height: 8),
            Text(
              granted ? 'Доступ разрешён' : 'Доступ запрещён',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: text,
              ),
            ),
            const SizedBox(height: 16),
            _UserInfoContent(
              result: result,
              textColor: text,
              subtextColor: subtext,
              iconBgColor: iconBg,
              accentColor: accent,
              avatarRadius: 32,
            ),
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
    final bgColor = granted
        ? const Color(0xFF2ECC71).withAlpha(230)
        : const Color(0xFFE74C3C).withAlpha(230);

    return GestureDetector(
      onTap: onDismiss,
      child: ColoredBox(
        color: bgColor,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    granted ? Icons.check_circle_rounded : Icons.cancel_rounded,
                    color: Colors.white,
                    size: 72,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    granted ? 'Доступ разрешён' : 'Доступ запрещён',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _UserInfoContent(
                    result: result,
                    textColor: Colors.white,
                    subtextColor: Colors.white70,
                    iconBgColor: Colors.white.withAlpha(40),
                    accentColor: Colors.white,
                    avatarRadius: 40,
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: onDismiss,
                    child: const Text('Закрыть',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
