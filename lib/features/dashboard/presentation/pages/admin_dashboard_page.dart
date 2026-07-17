import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Dashboard principal del AdminMaster — US-048 (base)
/// Drawer de navegación a todos los módulos del sistema
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateStreamProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Configuración',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      drawer: _AdminDrawer(userName: user?.name ?? ''),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bienvenida
            if (user != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.secondary.withValues(alpha: 0.1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hola, ${user.name.split(' ').first} 👋',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                          const Text('Panel de administración',
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            // Módulos de acceso rápido
            Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  _ModuleCard(icon: Icons.people_rounded, label: 'Cajeros', color: AppColors.primary,
                      onTap: () => context.push('/admin/users')),
                  _ModuleCard(icon: Icons.inventory_2_outlined, label: 'Productos', color: AppColors.secondary,
                      onTap: () => context.push('/admin/products')),
                  _ModuleCard(icon: Icons.bar_chart_rounded, label: 'Inventario', color: AppColors.warning,
                      onTap: () => context.push('/admin/inventory')),
                  _ModuleCard(icon: Icons.payments_outlined, label: 'Gastos', color: AppColors.error,
                      onTap: () => context.push('/admin/expenses')),
                  _ModuleCard(icon: Icons.receipt_long_rounded, label: 'Reportes', color: AppColors.info,
                      onTap: () {}),
                  _ModuleCard(icon: Icons.analytics_rounded, label: 'Estadísticas', color: AppColors.accent,
                      onTap: () {}),
                  _ModuleCard(icon: Icons.settings_outlined, label: 'Configuración', color: AppColors.textSecondary,
                      onTap: () => context.push('/settings')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _AdminDrawer extends StatelessWidget {
  final String userName;
  const _AdminDrawer({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceCard,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.storefront_rounded, color: AppColors.primary, size: 48),
            const SizedBox(height: 8),
            const Text('Abarrotería Pro', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            Text(userName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const Divider(height: 32),
            // Wrapped in Expanded+ListView to prevent Column overflow
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _drawerItem(context, Icons.dashboard_rounded, 'Dashboard', '/admin'),
                  const _DrawerSectionLabel('Turno y Caja'),
                  _drawerItem(context, Icons.point_of_sale_rounded, 'Historial de Cajas', '/admin/cash-registers'),
                  const _DrawerSectionLabel('Tienda'),
                  _drawerItem(context, Icons.people_rounded, 'Cajeros', '/admin/users'),
                  _drawerItem(context, Icons.inventory_2_outlined, 'Productos', '/admin/products'),
                  _drawerItem(context, Icons.bar_chart_rounded, 'Inventario', '/admin/inventory'),
                  _drawerItem(context, Icons.payments_outlined, 'Gastos', '/admin/expenses'),
                  const _DrawerSectionLabel('Reportes'),
                  _drawerItem(context, Icons.receipt_long_rounded, 'Reportes', '/admin/reports'),
                  _drawerItem(context, Icons.analytics_rounded, 'Estadísticas', '/admin/analytics'),
                ],

              ),
            ),
            const Divider(),
            _drawerItem(context, Icons.settings_outlined, 'Configuración', '/settings'),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _drawerItem(BuildContext context, IconData icon, String label, String route) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label),
      onTap: () {
        Navigator.pop(context);
        context.go(route);
      },
    );
  }
}

/// Etiqueta de sección en el Drawer del Admin
class _DrawerSectionLabel extends StatelessWidget {
  final String label;
  const _DrawerSectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: AppColors.textDisabled,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

