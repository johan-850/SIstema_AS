import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/confirmation_dialog.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// US-005 — Configuración general con logout seguro para AM y Cajero
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateStreamProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Perfil ────────────────────────────────────────
          if (user != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(height: 2),
                        Text(user.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            user.isAdmin ? 'Admin Master' : 'Cajero',
                            style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 8),

          // ── Cerrar sesión (US-005) ─────────────────────────
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: AppColors.error),
            title: const Text('Cerrar sesión', style: TextStyle(color: AppColors.error)),
            subtitle: const Text('Elimina el token de sesión local'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            onTap: () => _confirmLogout(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, WidgetRef ref) async {
    await ConfirmationDialog.show(
      context,
      title: 'Cerrar sesión',
      message: '¿Seguro que deseas cerrar tu sesión? Serás redirigido al login.',
      confirmLabel: 'Cerrar sesión',
      cancelLabel: 'Cancelar',
      isDangerous: true,
      onConfirm: () async {
        final result = await ref.read(logoutUseCaseProvider).call();
        if (context.mounted) {
          if (result.success) {
            context.go('/login');
          } else {
            AppSnackbar.error(context, result.failure?.message ?? 'Error al cerrar sesión');
          }
        }
      },
    );
  }
}
