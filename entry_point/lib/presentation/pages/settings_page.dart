import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/biometric_provider.dart';
import '../providers/theme_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final bio = ref.watch(biometricProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Настройки')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // ── Тема ──────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Text(
              'Оформление',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          _ThemeTile(
            icon: Icons.light_mode_rounded,
            title: 'Светлая тема',
            selected: themeMode == ThemeMode.light,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.light),
          ),
          _ThemeTile(
            icon: Icons.dark_mode_rounded,
            title: 'Тёмная тема',
            selected: themeMode == ThemeMode.dark,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.dark),
          ),
          _ThemeTile(
            icon: Icons.brightness_auto_rounded,
            title: 'Как в системе',
            selected: themeMode == ThemeMode.system,
            onTap: () =>
                ref.read(themeModeProvider.notifier).setMode(ThemeMode.system),
          ),

          const Divider(height: 32),

          // ── Безопасность ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Безопасность',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          SwitchListTile(
            secondary: Icon(
              bio.hasFace ? Icons.face_rounded : Icons.fingerprint_rounded,
              color: bio.isEnabled
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            title: const Text('Дополнительная защита'),
            subtitle: Text(
              bio.isAvailable
                  ? bio.isEnabled
                      ? '${bio.biometricLabel} включён'
                      : 'Вход через ${bio.biometricLabel}'
                  : 'Биометрия недоступна на устройстве',
            ),
            value: bio.isEnabled,
            onChanged: bio.isAvailable
                ? (value) async {
                    final ok = await ref
                        .read(biometricProvider.notifier)
                        .toggle(value);
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Не удалось включить биометрическую защиту'),
                        ),
                      );
                    }
                  }
                : null,
          ),
          if (bio.isAvailable)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'При включении для входа в приложение потребуется '
                'подтверждение через Face ID или отпечаток пальца.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

          const Divider(height: 32),

          // ── Навигация ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              'Аккаунт и устройства',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.devices_rounded),
            title: const Text('Мои устройства'),
            subtitle: const Text('Управление сессиями'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/devices'),
          ),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant),
      title: Text(title),
      trailing: selected
          ? Icon(Icons.check_circle_rounded,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
