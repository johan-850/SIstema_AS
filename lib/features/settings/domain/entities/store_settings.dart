// ============================================================
// lib/features/settings/domain/entities/store_settings.dart
// Configuración general del negocio (singleton) — QR de pago
// ============================================================

import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String? qrImageUrl;

  /// EP-06: monto a partir del cual un gasto se considera "elevado"
  /// (US-034) — null significa que el AdminMaster no configuró un límite.
  final double? maxExpenseAmount;

  /// EP-06: minutos durante los cuales un gasto recién registrado
  /// puede editarse (US-035).
  final int expenseEditWindowMinutes;

  const StoreSettings({
    this.qrImageUrl,
    this.maxExpenseAmount,
    this.expenseEditWindowMinutes = 10,
  });

  bool get hasQrImage => qrImageUrl != null && qrImageUrl!.isNotEmpty;

  @override
  List<Object?> get props => [qrImageUrl, maxExpenseAmount, expenseEditWindowMinutes];
}
