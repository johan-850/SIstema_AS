// ============================================================
// lib/features/pos/domain/repositories/sale_repository.dart
// Contrato del repositorio de ventas — Clean Architecture
// ============================================================

import '../entities/sale.dart';
import '../entities/cart_item.dart';
import '../../../../core/errors/failures.dart';

typedef SaleResult = ({Sale? sale, Failure? failure});

abstract class SaleRepository {
  /// US-030/US-031/US-032: confirma el cobro de una venta de forma
  /// atómica (vía función RPC en Supabase) — crea la venta, sus
  /// ítems y descuenta el stock correspondiente.
  Future<SaleResult> confirmSale({
    required String cashRegisterId,
    required String paymentMethod,
    double? cashAmount,
    double? transferAmount,
    required List<CartItem> items,
  });
}
