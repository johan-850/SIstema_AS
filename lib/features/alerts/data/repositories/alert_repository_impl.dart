// ============================================================
// lib/features/alerts/data/repositories/alert_repository_impl.dart
// Implementación del repositorio — convierte excepciones a Failures
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/alert.dart';
import '../../domain/repositories/alert_repository.dart';
import '../datasources/alert_remote_datasource.dart';
import '../../../../core/errors/failures.dart';

class AlertRepositoryImpl implements AlertRepository {
  final AlertRemoteDatasource _datasource;
  const AlertRepositoryImpl(this._datasource);

  Failure _mapException(Object e) {
    if (e is PostgrestException) {
      if (e.code == '42501' || e.message.contains('policy')) {
        return const PermissionFailure();
      }
      return ServerFailure(e.message);
    }
    return UnexpectedFailure(e.toString());
  }

  @override
  Future<AlertsResult> getAlerts() async {
    try {
      return (alerts: await _datasource.getAlerts(), failure: null);
    } catch (e) {
      return (alerts: <Alert>[], failure: _mapException(e));
    }
  }

  @override
  Future<Failure?> markReviewed(Alert alert) async {
    try {
      await _datasource.markReviewed(alert);
      return null;
    } catch (e) {
      return _mapException(e);
    }
  }

  @override
  Future<Failure?> unmarkReviewed(Alert alert) async {
    try {
      await _datasource.unmarkReviewed(alert);
      return null;
    } catch (e) {
      return _mapException(e);
    }
  }
}
