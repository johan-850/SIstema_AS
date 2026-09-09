// ============================================================
// lib/features/alerts/domain/repositories/alert_repository.dart
// Contrato del centro de alertas — US-061
// ============================================================

import '../entities/alert.dart';
import '../../../../core/errors/failures.dart';

typedef AlertsResult = ({List<Alert> alerts, Failure? failure});

abstract class AlertRepository {
  /// Alertas activas de las tres categorías, ya marcadas contra lo
  /// revisado y ordenadas (sin revisar primero, luego por gravedad).
  Future<AlertsResult> getAlerts();

  /// Marca la alerta como revisada. Para stock guarda la existencia
  /// actual, para poder volver a avisar si empeora.
  Future<Failure?> markReviewed(Alert alert);

  /// Deshace la revisión.
  Future<Failure?> unmarkReviewed(Alert alert);
}
