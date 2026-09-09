// ============================================================
// lib/features/alerts/presentation/providers/alert_providers.dart
// Centro de alertas — US-061
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/alert_remote_datasource.dart';
import '../../data/repositories/alert_repository_impl.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/errors/failures.dart';

// ── DI ──────────────────────────────────────────────────────────

final alertDatasourceProvider = Provider(
  (ref) => AlertRemoteDatasource(ref.read(supabaseClientProvider)),
);

final alertRepositoryProvider = Provider<AlertRepository>(
  (ref) => AlertRepositoryImpl(ref.read(alertDatasourceProvider)),
);

// ── Estado ──────────────────────────────────────────────────────

class AlertCenterState {
  final List<Alert> alerts;
  final bool isLoading;
  final Failure? failure;

  /// null = todas. Filtro de la barra superior.
  final AlertType? filterType;

  /// Las revisadas se ocultan por defecto: el centro es para lo que
  /// falta atender, no un historial.
  final bool showReviewed;

  const AlertCenterState({
    this.alerts = const [],
    this.isLoading = false,
    this.failure,
    this.filterType,
    this.showReviewed = false,
  });

  /// Lo que se muestra según los filtros activos.
  List<Alert> get visible => alerts
      .where((a) => showReviewed || !a.isReviewed)
      .where((a) => filterType == null || a.type == filterType)
      .toList();

  int get unreviewedCount => alerts.where((a) => !a.isReviewed).length;

  int unreviewedCountFor(AlertType type) =>
      alerts.where((a) => !a.isReviewed && a.type == type).length;

  AlertCenterState copyWith({
    List<Alert>? alerts,
    bool? isLoading,
    Failure? failure,
    bool clearFailure = false,
    AlertType? filterType,
    bool clearFilter = false,
    bool? showReviewed,
  }) =>
      AlertCenterState(
        alerts: alerts ?? this.alerts,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure ? null : (failure ?? this.failure),
        filterType: clearFilter ? null : (filterType ?? this.filterType),
        showReviewed: showReviewed ?? this.showReviewed,
      );
}

class AlertCenterNotifier extends StateNotifier<AlertCenterState> {
  final AlertRepository _repository;

  AlertCenterNotifier(this._repository) : super(const AlertCenterState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    final result = await _repository.getAlerts();
    if (!mounted) return;

    state = result.failure != null
        ? state.copyWith(isLoading: false, failure: result.failure)
        : state.copyWith(isLoading: false, alerts: result.alerts);
  }

  void filterBy(AlertType? type) =>
      state = state.copyWith(filterType: type, clearFilter: type == null);

  void toggleShowReviewed() => state = state.copyWith(showReviewed: !state.showReviewed);

  /// Marca o desmarca. Se aplica primero en memoria para que la
  /// respuesta sea inmediata, y se recarga después para que el estado
  /// refleje lo que realmente quedó guardado.
  Future<void> toggleReviewed(Alert alert) async {
    final wasReviewed = alert.isReviewed;

    state = state.copyWith(
      alerts: [
        for (final a in state.alerts)
          (a.type == alert.type && a.key == alert.key) ? a.copyWith(isReviewed: !wasReviewed) : a,
      ],
    );

    final failure = wasReviewed
        ? await _repository.unmarkReviewed(alert)
        : await _repository.markReviewed(alert);
    if (!mounted) return;

    if (failure != null) {
      // Falló: se revierte el cambio optimista y se avisa.
      state = state.copyWith(
        alerts: [
          for (final a in state.alerts)
            (a.type == alert.type && a.key == alert.key) ? a.copyWith(isReviewed: wasReviewed) : a,
        ],
        failure: failure,
      );
      return;
    }

    await load();
  }
}

final alertCenterProvider =
    StateNotifierProvider.autoDispose<AlertCenterNotifier, AlertCenterState>(
  (ref) => AlertCenterNotifier(ref.read(alertRepositoryProvider)),
);

/// Contador para el dashboard. Separado del estado de la pantalla
/// porque vive mientras el dashboard esté abierto, no la lista.
final unreviewedAlertCountProvider = FutureProvider<int>((ref) async {
  final result = await ref.read(alertRepositoryProvider).getAlerts();
  return result.alerts.where((a) => !a.isReviewed).length;
});
