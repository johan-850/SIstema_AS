// ============================================================
// lib/features/cash_register/domain/entities/cash_register.dart
// Entidad de negocio para el registro de caja (apertura/cierre de turno)
// Cubre: US-008, US-009, US-010, US-012
// ============================================================

import 'package:equatable/equatable.dart';
import '../../../../core/constants/app_constants.dart';

/// Representa una apertura (y eventual cierre) de caja de un turno.
///
/// El [openingBreakdown] almacena las cantidades de cada denominación:
///   { 'coin_50': 10, 'bill_5000': 3, ... }
/// con las claves definidas en [AppConstants.coinDenominations] y
/// [AppConstants.billDenominations].
class CashRegister extends Equatable {
  final String id;
  final String cashierId;
  final String? cashierName;         // Desnormalizado para listados

  /// Monto total de apertura (suma calculada del desglose)
  final double openingAmount;

  /// Desglose de denominaciones al abrir {'coin_50': qty, 'bill_1000': qty, ...}
  final Map<String, int> openingBreakdown;

  /// Notas opcionales del cajero al iniciar el turno (máx. 300 chars)
  final String? notes;

  final double? closingAmount;
  final Map<String, int>? closingBreakdown;

  /// Timestamp UTC de apertura — no editable (US-012)
  final DateTime openingTime;
  final DateTime? closingTime;

  /// 'open' | 'closed'
  final String status;

  final DateTime createdAt;
  final DateTime updatedAt;

  const CashRegister({
    required this.id,
    required this.cashierId,
    this.cashierName,
    required this.openingAmount,
    required this.openingBreakdown,
    this.notes,
    this.closingAmount,
    this.closingBreakdown,
    required this.openingTime,
    this.closingTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Devuelve true si la caja está actualmente abierta
  bool get isOpen => status == 'open';

  /// Calcula el total de apertura a partir del desglose
  static double calculateTotal(Map<String, int> breakdown) {
    double total = 0;
    for (final entry in breakdown.entries) {
      final denomValue = AppConstants.coinDenominations[entry.key] ??
          AppConstants.billDenominations[entry.key] ??
          0;
      total += denomValue * entry.value;
    }
    return total;
  }

  CashRegister copyWith({
    double? closingAmount,
    Map<String, int>? closingBreakdown,
    DateTime? closingTime,
    String? status,
    DateTime? updatedAt,
  }) =>
      CashRegister(
        id: id,
        cashierId: cashierId,
        cashierName: cashierName,
        openingAmount: openingAmount,
        openingBreakdown: openingBreakdown,
        notes: notes,
        closingAmount: closingAmount ?? this.closingAmount,
        closingBreakdown: closingBreakdown ?? this.closingBreakdown,
        openingTime: openingTime,
        closingTime: closingTime ?? this.closingTime,
        status: status ?? this.status,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  List<Object?> get props => [id, cashierId, status, openingTime];
}
