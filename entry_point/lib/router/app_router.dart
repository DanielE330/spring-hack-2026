import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/utils/app_logger.dart';
import '../presentation/providers/auth_provider.dart';
import '../presentation/pages/splash_page.dart';
import '../presentation/pages/home_page.dart';
import '../presentation/pages/qr_page.dart';
import '../presentation/pages/scanner_page.dart';
import '../presentation/pages/devices_page.dart';
import '../presentation/pages/profile_page.dart';
import '../presentation/pages/auth/login_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Создаём роутер ОДИН РАЗ.
  // Redirect читает состояние через ref.read — не пересоздаёт роутер.
  // ref.listen запускает router.refresh() при изменении auth, чтобы
  // redirect переоценил условия без пересоздания GoRouter.
  final router = GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final auth = ref.read(authProvider);
      final loc = state.matchedLocation;
      final isInitial = auth.status == AuthStatus.initial;
      final isAuth = auth.status == AuthStatus.authenticated;
      final isOnAuth = loc == '/login';

      // Splash сам управляет навигацией — redirect не трогает его
      if (loc == '/') return null;
      if (isInitial) return '/';

      if (!isAuth && !isOnAuth) {
        AppLogger.nav(loc, '/login');
        return '/login';
      }
      if (isAuth && isOnAuth) {
        AppLogger.nav(loc, '/home');
        return '/home';
      }
      // Admin guard для сканера
      if (loc == '/scan' && !auth.isAdmin) {
        AppLogger.nav(loc, '/home');
        return '/home';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) {
          AppLogger.nav('router', '/login');
          return const LoginPage();
        },
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          AppLogger.nav('router', '/home');
          return const HomePage();
        },
      ),
      GoRoute(
        path: '/qr',
        builder: (context, state) {
          AppLogger.nav('router', '/qr');
          return const QrPage();
        },
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) {
          AppLogger.nav('router', '/scan');
          return const ScannerPage();
        },
      ),
      GoRoute(
        path: '/devices',
        builder: (context, state) {
          AppLogger.nav('router', '/devices');
          return const DevicesPage();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) {
          AppLogger.nav('router', '/profile');
          return const ProfilePage();
        },
      ),
    ],
  );

  // При каждом изменении auth-состояния переоцениваем redirect
  // без пересоздания GoRouter
  ref.listen(authProvider, (_, _) => router.refresh());

  return router;
});
