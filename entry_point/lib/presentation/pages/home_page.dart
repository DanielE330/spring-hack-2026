import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/auth_provider.dart';
import '../providers/devices_provider.dart';
import '../widgets/qr_pass_widget.dart';

bool get _isMobile =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

Future<void> _downloadReport(BuildContext context, WidgetRef ref) async {
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(
    const SnackBar(content: Text('Загрузка отчёта...')),
  );
  try {
    final bytes = await ref.read(devicesProvider.notifier).downloadReport();
    if (!context.mounted) return;
    if (bytes == null || bytes.isEmpty) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(content: Text('Не удалось получить отчёт')),
      );
      return;
    }
    final now = DateTime.now();
    final filename = 'attendance_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}.xlsx';
    final uint8Bytes = Uint8List.fromList(bytes);

    if (_isMobile) {
      // На мобилке — сохраняем во временную папку и открываем системный шаринг
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/$filename');
      await file.writeAsBytes(uint8Bytes);
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
          title: 'Отчёт посещаемости',
        ),
      );
    } else {
      // На десктопе — просто сохраняем файл
      await FileSaver.instance.saveFile(
        name: filename,
        bytes: uint8Bytes,
        mimeType: MimeType.microsoftExcel,
      );
      if (context.mounted) {
        messenger.hideCurrentSnackBar();
        messenger.showSnackBar(
          const SnackBar(content: Text('Отчёт сохранён ✅')),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Ошибка загрузки: $e')),
      );
    }
  }
}

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final user = auth.user;
    final isAdmin = auth.isAdmin;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SvgPicture.asset(
                'assets/icons/rostelecomatar.svg',
                width: 32,
                height: 32,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Точка входа'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Настройки',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
              // Greeting card — tap to open profile
              InkWell(
                onTap: () => context.push('/profile'),
                borderRadius: BorderRadius.circular(12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          backgroundImage: user?.avatarUrl != null
                              ? NetworkImage(user!.avatarUrl!)
                              : null,
                          child: user?.avatarUrl == null
                              ? Text(
                                  user?.initials ?? '?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.fullName ?? 'Пользователь',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                isAdmin ? 'Администратор' : 'Пользователь',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // QR-пропуск с круговым таймером
              const QrPassWidget(),
              const SizedBox(height: 16),

              // Admin-only actions
              if (isAdmin) ...[
                _ActionButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Сканировать QR',
                  subtitle: 'Проверка пропуска',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => context.push('/scan'),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.person_add_rounded,
                  label: 'Создать пользователя',
                  subtitle: 'Добавить сотрудника',
                  color: Theme.of(context).colorScheme.secondary,
                  onTap: () => context.push('/create-user'),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  icon: Icons.file_download_rounded,
                  label: 'Выгрузить отчёт',
                  subtitle: 'Посещаемость (Excel)',
                  color: Theme.of(context).colorScheme.tertiary,
                  onTap: () => _downloadReport(context, ref),
                ),
                const SizedBox(height: 16),
              ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final containerBg = isDark ? color.withAlpha(30) : color.withAlpha(18);
    final iconBg = isDark ? color.withAlpha(50) : color.withAlpha(30);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final subtColor = isDark ? Colors.white70 : const Color(0xFF5C5C70);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: containerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(isDark ? 60 : 50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold, color: textColor)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: subtColor)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: color.withAlpha(180)),
          ],
        ),
      ),
    );
  }
}
