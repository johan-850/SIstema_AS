// ============================================================
// lib/features/pos/domain/use_cases/sale_use_cases.dart
// Caso de uso de cobro — US-030, US-031, US-032
// ============================================================

import '../entities/cart_item.dart';
import '../repositories/sale_repository.dart';

/// Confirma el cobro de la venta actual (entrada/salida de stock
/// atómica ya resuelta por la función RPC en el repositorio).
class ConfirmSaleUseCase {
  final SaleRepository _repository;
  const ConfirmSaleUseCase(this._repository);

  Future<SaleResult> call({
    required String cashRegisterId,
    required String paymentMethod,
    double? cashAmount,
    double? transferAmount,
    required List<CartItem> items,
  }) =>
      _repository.confirmSale(
        cashRegisterId: cashRegisterId,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        transferAmount: transferAmount,
        items: items,
      );
}
