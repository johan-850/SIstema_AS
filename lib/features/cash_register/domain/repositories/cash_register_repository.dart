// ============================================================
// lib/features/cash_register/domain/repositories/cash_register_repository.dart
// Contrato del repositorio — capa de dominio
// ============================================================

import '../entities/cash_register.dart';
import '../../../../core/errors/failures.dart';

// ── Result types ─────────────────────────────────────────────

typedef CashRegisterResult = ({CashRegister? register, Failure? failure});
typedef CashRegisterListResult = ({List<CashRegister> registers, Failure? failure});
typedef BoolResult = ({bool value, Failure? failure});

// ── Interfaz ─────────────────────────────────────────────────

abstract interface class CashRegisterRepository {
  /// Verifica si el cajero tiene una caja abierta HOY.
  /// Retorna la caja activa o null si no hay ninguna.
  Future<CashRegisterResult> getActiveRegister(String cashierId);

  /// Abre una nueva caja de caja registrando el desglose y las notas.
  /// [openingBreakdown] sigue el esquema de [AppConstants.coinDenominations]
  /// y [AppConstants.billDenominations].
  Future<CashRegisterResult> openRegister({
    required String cashierId,
    required Map<String, int> openingBreakdown,
    required double openingAmount,
    String? notes,
  });

  /// Obtiene el historial paginado de aperturas (solo AdminMaster).
  /// Permite filtrar por [cashierId] y/o rango de fechas.
  Future<CashRegisterListResult> getRegisterHistory({
    String? cashierId,
    DateTime? from,
    DateTime? to,
    int page = 0,
    int pageSize = 20,
  });
}
