// ============================================================
// lib/features/pos/data/datasources/sale_remote_datasource.dart
// Datasource remoto — llama a la función RPC confirm_sale
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/sale.dart';
import '../../domain/entities/cart_item.dart';
import '../../../../core/constants/app_constants.dart';

class SaleRemoteDatasource {
  final SupabaseClient _client;
  const SaleRemoteDatasource(this._client);

  Sale _fromJson(Map<String, dynamic> json) => Sale(
        id: json['id'] as String,
        total: (json['total'] as num).toDouble(),
        paymentMethod: json['payment_method'] as String,
        cashAmount: (json['cash_amount'] as num?)?.toDouble(),
        transferAmount: (json['transfer_amount'] as num?)?.toDouble(),
        changeAmount: (json['change_amount'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Future<Sale> confirmSale({
    required String cashRegisterId,
    required String paymentMethod,
    double? cashAmount,
    double? transferAmount,
    required List<CartItem> items,
  }) async {
    final response = await _client.rpc(AppConstants.rpcConfirmSale, params: {
      'p_cash_register_id': cashRegisterId,
      'p_payment_method': paymentMethod,
      'p_cash_amount': cashAmount,
      'p_transfer_amount': transferAmount,
      'p_items': items
          .map((i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
                'unit_price': i.unitPrice,
                'product_name': i.name,
              })
          .toList(),
    });

    return _fromJson(response as Map<String, dynamic>);
  }
}
