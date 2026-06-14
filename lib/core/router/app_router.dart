import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../../features/dashboard/presentation/pages/admin_dashboard_page.dart';
import '../../features/cash_register/presentation/pages/cash_register_opening_page.dart';
import '../../features/pos/presentation/pages/pos_page.dart';
import '../../features/users/presentation/pages/users_list_page.dart';
import '../../features/users/presentation/pages/create_cashier_page.dart';
import '../../features/users/presentation/pages/cashier_detail_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

// ── Rutas nombradas ─────────────────────────────────────────
abstract class AppRoutes {
  static const login = '/login';
  static const adminDashboard = '/admin';
  static const cashRegisterOpening = '/cash-register/opening';
  static const pos = '/pos';
  static const products = '/admin/products';
  static const inventory = '/admin/inventory';
  static const users = '/admin/users';
  static const createCashier = '/admin/users/create';
  static const cashierDetail = '/admin/users/:id';
  static const settings = '/settings';
  static const reports = '/admin/reports';
  static const analytics = '/admin/analytics';
}

// ── Provider del router ─────────────────────────────────────
final appRouterProvider = Provider<GoRouter>((ref) {
  final authStream = ref.watch(authStateStreamProvider);

  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isLoggedIn = authStream.valueOrNull != null;
      final isLoginPage = state.matchedLocation == AppRoutes.login;

      if (!isLoggedIn && !isLoginPage) return AppRoutes.login;
      if (isLoggedIn && isLoginPage) {
        final role = ref.read(currentUserRoleProvider);
        return role == 'adminmaster'
            ? AppRoutes.adminDashboard
            : AppRoutes.cashRegisterOpening;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.adminDashboard,
        name: 'admin-dashboard',
        builder: (_, __) => const AdminDashboardPage(),
      ),
      GoRoute(
        path: AppRoutes.cashRegisterOpening,
        name: 'cash-register-opening',
        builder: (_, __) => const CashRegisterOpeningPage(),
      ),
      GoRoute(
        path: AppRoutes.pos,
        name: 'pos',
        builder: (_, __) => const PosPage(),
      ),
      GoRoute(
        path: AppRoutes.users,
        name: 'users',
        builder: (_, __) => const UsersListPage(),
      ),
      GoRoute(
        path: AppRoutes.createCashier,
        name: 'create-cashier',
        builder: (_, __) => const CreateCashierPage(),
      ),
      GoRoute(
        path: AppRoutes.cashierDetail,
        name: 'cashier-detail',
        builder: (_, state) => CashierDetailPage(cashierId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (_, __) => const SettingsPage(),
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Ruta no encontrada: ${state.error}')),
    ),
  );
});
