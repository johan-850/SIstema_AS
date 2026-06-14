// ============================================================
// lib/core/router/app_router.dart
// GoRouter con guards de autenticación por rol
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/cash_register/presentation/pages/cash_register_opening_page.dart';
import '../../features/pos/presentation/pages/pos_page.dart';

// ── Rutas nombradas ─────────────────────────────────────────
abstract class AppRoutes {
  static const login = '/login';
  static const adminDashboard = '/admin';
  static const cashRegisterOpening = '/cash-register/opening';
  static const pos = '/pos';
  static const products = '/admin/products';
  static const inventory = '/admin/inventory';
  static const expenses = '/expenses';
  static const closing = '/cash-register/closing';
  static const reports = '/admin/reports';
  static const analytics = '/admin/analytics';
  static const users = '/admin/users';
  static const settings = '/settings';
  static const bluetooth = '/settings/bluetooth';
  static const notifications = '/notifications';
}

// ── Provider del router ─────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    refreshListenable: GoRouterRefreshStream(
      ref.watch(authStateChangesProvider.stream),
    ),
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginPage) return AppRoutes.login;
      if (isLoggedIn && isLoginPage) {
        // Redirigir según rol
        final role = ref.read(currentUserRoleProvider);
        if (role == 'adminmaster') return AppRoutes.adminDashboard;
        return AppRoutes.cashRegisterOpening;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.cashRegisterOpening,
        name: 'cash-register-opening',
        builder: (context, state) => const CashRegisterOpeningPage(),
      ),
      GoRoute(
        path: AppRoutes.pos,
        name: 'pos',
        builder: (context, state) => const PosPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Página no encontrada: ${state.error}'),
      ),
    ),
  );
});

// ── Helper: convierte Stream en Listenable ──────────────────
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final dynamic _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
