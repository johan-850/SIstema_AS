// ============================================================
// lib/features/pos/data/repositories/sale_repository_impl.dart
// Implementación del repositorio — convierte excepciones a Failures
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/cart_item.dart';
import '../../domain/repositories/sale_repository.dart';
import '../datasources/sale_remote_datasource.dart';
import '../../../../core/errors/failures.dart';

class SaleRepositoryImpl implements SaleRepository {
  final SaleRemoteDatasource _datasource;
  const SaleRepositoryImpl(this._datasource);

  /// Los errores de confirm_sale() (RAISE EXCEPTION) llegan como
  /// PostgrestException con un mensaje ya listo para el usuario
  /// (ej. "Stock insuficiente para...").
  Failure _mapException(Object e) {
    if (e is PostgrestException) {
      if (e.code == '42501' || e.message.contains('policy')) {
        return const PermissionFailure();
      }
      return ValidationFailure(e.message);
    }
    return UnexpectedFailure(e.toString());
  }

  @override
  Future<SaleResult> confirmSale({
    required String cashRegisterId,
    required String paymentMethod,
    double? cashAmount,
    double? transferAmount,
    required List<CartItem> items,
  }) async {
    try {
      final sale = await _datasource.confirmSale(
        cashRegisterId: cashRegisterId,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        transferAmount: transferAmount,
        items: items,
      );
      return (sale: sale, failure: null);
    } catch (e) {
      return (sale: null, failure: _mapException(e));
    }
  }
}
