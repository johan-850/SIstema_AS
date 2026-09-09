// ============================================================
// lib/features/alerts/data/datasources/alert_remote_datasource.dart
// Compone las alertas del centro a partir de tres fuentes que ya
// existen — US-061. No hay tabla de alertas: se derivan.
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/alert.dart';

class AlertRemoteDatasource {
  final SupabaseClient _client;
  const AlertRemoteDatasource(this._client);

  /// Cuántos cuadres y gastos recientes se revisan. Sin tope, con el
  /// tiempo la pantalla traería años de historia para nada: una alerta
  /// de hace seis meses ya no es accionable.
  static const int _historyLimit = 100;

  Future<List<Alert>> getAlerts() async {
    // Los umbrales viven en store_settings y hasta ahora casi ningún
    // lado los respetaba (ver US-061). Acá son la única fuente.
    final settings = await _client
        .from(AppConstants.tableStoreSettings)
        .select('max_expense_amount, cash_diff_comment_threshold')
        .eq('id', 1)
        .maybeSingle();

    final maxExpense = (settings?['max_expense_amount'] as num?)?.toDouble();
    final diffThreshold =
        (settings?['cash_diff_comment_threshold'] as num?)?.toDouble() ?? 5000;

    final reviews = await _getReviews();

    final alerts = <Alert>[
      ...await _stockAlerts(),
      ...await _cuadreAlerts(diffThreshold),
      ...await _gastoAlerts(maxExpense),
    ];

    // Se marca cada alerta contra su revisión, aplicando la regla de
    // isAlertReviewed (el stock puede "des-revisarse" si empeora).
    final resolved = alerts.map((a) {
      final review = reviews['${a.type.value}:${a.key}'];
      return a.copyWith(isReviewed: isAlertReviewed(a, review));
    }).toList();

    // Sin revisar primero; dentro de cada grupo, lo más grave y reciente.
    resolved.sort((a, b) {
      if (a.isReviewed != b.isReviewed) return a.isReviewed ? 1 : -1;
      if (a.severity != b.severity) return a.severity == AlertSeverity.critical ? -1 : 1;
      return b.date.compareTo(a.date);
    });

    return resolved;
  }

  Future<Map<String, AlertReview>> _getReviews() async {
    final rows = await _client
        .from(AppConstants.tableAlertReviews)
        .select('alert_type, alert_key, context_value') as List;

    return {
      for (final r in rows.cast<Map<String, dynamic>>())
        '${r['alert_type']}:${r['alert_key']}': (
          alertKey: r['alert_key'] as String,
          type: AlertTypeX.fromValue(r['alert_type'] as String),
          contextValue: (r['context_value'] as num?)?.toDouble(),
        ),
    };
  }

  /// Productos activos en o por debajo de su mínimo.
  ///
  /// El filtro se hace en Dart porque PostgREST no puede comparar dos
  /// columnas entre sí (`stock <= min_stock`) — mismo criterio que ya
  /// usa el dashboard de inventario.
  Future<List<Alert>> _stockAlerts() async {
    final rows = await _client
        .from(AppConstants.tableProducts)
        .select('id, name, stock, min_stock, updated_at')
        .eq('is_active', true) as List;

    final alerts = <Alert>[];
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final stock = (r['stock'] as num).toInt();
      final minStock = (r['min_stock'] as num).toInt();
      if (stock > minStock) continue;

      alerts.add(Alert(
        type: AlertType.stock,
        key: r['id'] as String,
        title: r['name'] as String,
        detail: stock <= 0
            ? 'Agotado (mínimo: $minStock)'
            : 'Quedan $stock — mínimo: $minStock',
        date: DateTime.parse(r['updated_at'] as String),
        severity: stock <= 0 ? AlertSeverity.critical : AlertSeverity.warning,
        contextValue: stock.toDouble(),
      ));
    }
    return alerts;
  }

  /// Cajas cerradas cuya diferencia supera el umbral configurado.
  Future<List<Alert>> _cuadreAlerts(double threshold) async {
    final rows = await _client
        .from(AppConstants.tableCashRegisters)
        .select('id, closing_time, closing_summary, profiles(name)')
        .eq('status', 'closed')
        .order('closing_time', ascending: false)
        .limit(_historyLimit) as List;

    final alerts = <Alert>[];
    for (final r in rows.cast<Map<String, dynamic>>()) {
      final summary = r['closing_summary'] as Map<String, dynamic>?;
      if (summary == null) continue;

      final difference = (summary['difference'] as num?)?.toDouble() ?? 0;
      if (difference.abs() <= threshold) continue;

      final cashier = (r['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? 'Cajero';
      final closingTime = r['closing_time'] as String?;

      alerts.add(Alert(
        type: AlertType.cuadre,
        key: r['id'] as String,
        title: 'Diferencia de caja — $cashier',
        detail: difference < 0
            ? 'Faltaron \$${difference.abs().toStringAsFixed(0)}'
            : 'Sobraron \$${difference.toStringAsFixed(0)}',
        date: closingTime != null ? DateTime.parse(closingTime) : DateTime.now(),
        // Un faltante es peor que un sobrante: puede ser un error de
        // cobro o algo más serio; un sobrante casi siempre es un vuelto
        // mal dado.
        severity: difference < 0 ? AlertSeverity.critical : AlertSeverity.warning,
      ));
    }
    return alerts;
  }

  /// Gastos por encima del máximo configurado.
  ///
  /// Si no hay máximo configurado esta categoría no genera alertas: sin
  /// umbral no hay forma de decir qué es "elevado".
  Future<List<Alert>> _gastoAlerts(double? maxExpense) async {
    if (maxExpense == null || maxExpense <= 0) return [];

    final rows = await _client
        .from(AppConstants.tableExpenses)
        .select('id, amount, category_name, description, created_at, profiles(name)')
        .gt('amount', maxExpense)
        .order('created_at', ascending: false)
        .limit(_historyLimit) as List;

    return rows.cast<Map<String, dynamic>>().map((r) {
      final amount = (r['amount'] as num).toDouble();
      final cashier = (r['profiles'] as Map<String, dynamic>?)?['name'] as String? ?? 'Cajero';
      final description = r['description'] as String? ?? '';

      return Alert(
        type: AlertType.gasto,
        key: r['id'] as String,
        title: '${r['category_name']} — \$${amount.toStringAsFixed(0)}',
        detail: description.isEmpty
            ? 'Registrado por $cashier (máximo: \$${maxExpense.toStringAsFixed(0)})'
            : '$description · $cashier',
        date: DateTime.parse(r['created_at'] as String),
        severity: AlertSeverity.warning,
      );
    }).toList();
  }

  /// Marca una alerta como revisada. Para stock guarda además el stock
  /// actual, para poder volver a avisar si empeora.
  Future<void> markReviewed(Alert alert) async {
    await _client.from(AppConstants.tableAlertReviews).upsert(
      {
        'alert_type': alert.type.value,
        'alert_key': alert.key,
        'context_value': alert.contextValue,
        'reviewed_by': _client.auth.currentUser?.id,
        'reviewed_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'alert_type,alert_key',
    );
  }

  Future<void> unmarkReviewed(Alert alert) async {
    await _client
        .from(AppConstants.tableAlertReviews)
        .delete()
        .eq('alert_type', alert.type.value)
        .eq('alert_key', alert.key);
  }
}
