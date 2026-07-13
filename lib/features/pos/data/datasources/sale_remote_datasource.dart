// ============================================================
// lib/features/pos/data/datasources/sale_remote_datasource.dart
// Datasource remoto — llama a la función RPC confirm_sale
// ============================================================

import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

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
        receiptPhotoUrl: json['receipt_photo_url'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Future<Sale> confirmSale({
    required String cashRegisterId,
    required String paymentMethod,
    double? cashAmount,
    double? transferAmount,
    required List<CartItem> items,
    String? receiptPhotoUrl,
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
      'p_receipt_photo_url': receiptPhotoUrl,
    });

    return _fromJson(response as Map<String, dynamic>);
  }

  /// Sube la foto del comprobante de transferencia a Storage y devuelve
  /// su URL pública. Mismo patrón que uploadProductImage (EP-03).
  Future<String> uploadReceiptPhoto(Uint8List bytes, String fileExt) async {
    final path = 'receipts/${const Uuid().v4()}.$fileExt';
    await _client.storage
        .from(AppConstants.storageBucketReceiptPhotos)
        .uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));

    return _client.storage
        .from(AppConstants.storageBucketReceiptPhotos)
        .getPublicUrl(path);
  }

  /// Borra una foto de comprobante a partir de su URL pública.
  /// Best-effort: no propaga errores (ej. el cajero retomó la foto).
  Future<void> deleteReceiptPhoto(String photoUrl) async {
    try {
      final marker = '/object/public/${AppConstants.storageBucketReceiptPhotos}/';
      final idx = photoUrl.indexOf(marker);
      if (idx == -1) return;
      final path = photoUrl.substring(idx + marker.length);
      await _client.storage.from(AppConstants.storageBucketReceiptPhotos).remove([path]);
    } catch (_) {
      /* No crítico */
    }
  }

  /// US-032: cashier_id se completa server-side (DEFAULT auth.uid())
  /// — no hace falta ni conviene mandarlo desde el cliente.
  Future<void> logCancelledSale({
    required String cashRegisterId,
    required int itemsCount,
    required double totalAmount,
  }) async {
    await _client.from(AppConstants.tableSaleCancellations).insert({
      'cash_register_id': cashRegisterId,
      'items_count': itemsCount,
      'total_amount': totalAmount,
    });
  }

  /// US-059: idem, cashier_id server-side.
  Future<void> logLowStockAlert({
    required String productId,
    required String productName,
    required int stock,
  }) async {
    await _client.from(AppConstants.tableLowStockAlerts).insert({
      'product_id': productId,
      'product_name': productName,
      'stock_at_alert': stock,
    });
  }
}
