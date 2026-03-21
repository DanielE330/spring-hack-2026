import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/biometric_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _biometricFailed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    await ref.read(authProvider.notifier).init();
    if (!mounted) return;
    final status = ref.read(authProvider).status;
    if (status == AuthStatus.authenticated) {
      // Проверяем биометрию, если включена
      final bio = ref.read(biometricProvider);
      if (bio.isEnabled && !bio.isAuthenticated) {
        final ok = await ref.read(biometricProvider.notifier).authenticate();
        if (!ok) {
          // Пользователь не прошёл — показываем кнопку повторной попытки
          if (mounted) {
            setState(() => _biometricFailed = true);
          }
          return;
        }
      }
      if (mounted) context.go('/home');
    } else {
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SvgPicture.asset(
                'assets/icons/rostelecomatar.svg',
                width: 96,
                height: 96,
              ),
            ),
            const SizedBox(height: 24),
            Text('Entry Point',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Ростелеком',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 32),
            if (_biometricFailed) ...[
              Icon(Icons.fingerprint_rounded,
                  size: 48,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(
                'Подтвердите вашу личность',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() => _biometricFailed = false);
                  _checkAuth();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Повторить'),
              ),
            ] else
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
