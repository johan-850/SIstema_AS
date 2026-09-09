// ============================================================
// lib/features/alerts/presentation/pages/alert_center_page.dart
// US-061: centro de alertas del AdminMaster — stock bajo,
// diferencias de cuadre y gastos elevados en un solo lugar.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/alert.dart';
import '../providers/alert_providers.dart';

class AlertCenterPage extends ConsumerWidget {
  const AlertCenterPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(alertCenterProvider);
    final notifier = ref.read(alertCenterProvider.notifier);

    ref.listen<AlertCenterState>(alertCenterProvider, (_, next) {
      if (next.failure != null) {
        AppSnackbar.error(context, next.failure!.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Centro de alertas'),
        actions: [
          IconButton(
            tooltip: state.showReviewed ? 'Ocultar revisadas' : 'Mostrar revisadas',
            icon: Icon(state.showReviewed
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined),
            onPressed: notifier.toggleShowReviewed,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: notifier.load,
        child: Column(
          children: [
            _FilterBar(state: state, onSelect: notifier.filterBy),
            Expanded(
              child: state.isLoading && state.alerts.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _AlertList(state: state, notifier: notifier),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final AlertCenterState state;
  final ValueChanged<AlertType?> onSelect;

  const _FilterBar({required this.state, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _FilterChip(
            label: 'Todas',
            count: state.unreviewedCount,
            selected: state.filterType == null,
            onTap: () => onSelect(null),
          ),
          const SizedBox(width: 8),
          ...AlertType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _FilterChip(
                  label: type.label,
                  count: state.unreviewedCountFor(type),
                  selected: state.filterType == type,
                  onTap: () => onSelect(type),
                ),
              )),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: const TextStyle(
                        color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertList extends StatelessWidget {
  final AlertCenterState state;
  final AlertCenterNotifier notifier;

  const _AlertList({required this.state, required this.notifier});

  @override
  Widget build(BuildContext context) {
    final visible = state.visible;

    if (visible.isEmpty) {
      // Con scroll para que "deslizar para actualizar" siga funcionando
      // aunque no haya nada que mostrar.
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            state.alerts.isEmpty ? Icons.check_circle_outline_rounded : Icons.filter_alt_off_outlined,
            size: 56,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            state.alerts.isEmpty
                ? 'Todo en orden: no hay alertas activas.'
                : 'No hay alertas con este filtro.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: visible.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AlertCard(
        alert: visible[i],
        onToggleReviewed: () => notifier.toggleReviewed(visible[i]),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final Alert alert;
  final VoidCallback onToggleReviewed;

  const _AlertCard({required this.alert, required this.onToggleReviewed});

  /// Cada categoría lleva a la pantalla donde de verdad se resuelve.
  static ({String route, String label}) _actionFor(AlertType type) => switch (type) {
        AlertType.stock => (route: '/admin/inventory/restock', label: 'Ver restock'),
        AlertType.cuadre => (route: '/admin/cash-registers', label: 'Ver cuadres'),
        AlertType.gasto => (route: '/admin/expenses', label: 'Ver gastos'),
      };

  static IconData _iconFor(AlertType type) => switch (type) {
        AlertType.stock => Icons.inventory_2_outlined,
        AlertType.cuadre => Icons.point_of_sale_rounded,
        AlertType.gasto => Icons.payments_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy hh:mm a', 'es');
    final action = _actionFor(alert.type);
    final accent = alert.severity == AlertSeverity.critical ? AppColors.error : AppColors.warning;

    return Opacity(
      // Las revisadas se atenúan en vez de esconderse cuando el admin
      // pide verlas: siguen ahí, pero no compiten por atención.
      opacity: alert.isReviewed ? 0.55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: alert.isReviewed ? AppColors.border : accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(_iconFor(alert.type), color: accent, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          decoration: alert.isReviewed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(alert.detail,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(dateFmt.format(alert.date.toLocal()),
                          style: const TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => context.push(action.route),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: Text(action.label, style: const TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 4),
                TextButton.icon(
                  onPressed: onToggleReviewed,
                  icon: Icon(
                    alert.isReviewed ? Icons.undo_rounded : Icons.check_rounded,
                    size: 16,
                    color: alert.isReviewed ? AppColors.textSecondary : AppColors.success,
                  ),
                  label: Text(
                    alert.isReviewed ? 'Deshacer' : 'Revisada',
                    style: TextStyle(
                      fontSize: 12,
                      color: alert.isReviewed ? AppColors.textSecondary : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
