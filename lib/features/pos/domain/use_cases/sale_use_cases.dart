// ============================================================
// lib/features/pos/domain/use_cases/sale_use_cases.dart
// Caso de uso de cobro — US-030, US-031, US-032
// ============================================================

import 'dart:typed_data';

import '../entities/cart_item.dart';
import '../repositories/sale_repository.dart';
import '../../../../core/errors/failures.dart';

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
    String? receiptPhotoUrl,
  }) =>
      _repository.confirmSale(
        cashRegisterId: cashRegisterId,
        paymentMethod: paymentMethod,
        cashAmount: cashAmount,
        transferAmount: transferAmount,
        items: items,
        receiptPhotoUrl: receiptPhotoUrl,
      );
}

/// Sube la foto del comprobante de transferencia (antes de confirmar el cobro).
class UploadReceiptPhotoUseCase {
  final SaleRepository _repository;
  const UploadReceiptPhotoUseCase(this._repository);

  Future<({String? url, Failure? failure})> call(Uint8List bytes, String fileExt) =>
      _repository.uploadReceiptPhoto(bytes, fileExt);
}

/// Borra una foto de comprobante ya subida (ej. el cajero la retoma).
class DeleteReceiptPhotoUseCase {
  final SaleRepository _repository;
  const DeleteReceiptPhotoUseCase(this._repository);

  Future<void> call(String photoUrl) => _repository.deleteReceiptPhoto(photoUrl);
}

/// US-032: registra la cancelación del carrito para auditoría.
class LogCancelledSaleUseCase {
  final SaleRepository _repository;
  const LogCancelledSaleUseCase(this._repository);

  Future<Failure?> call({
    required String cashRegisterId,
    required int itemsCount,
    required double totalAmount,
  }) =>
      _repository.logCancelledSale(
        cashRegisterId: cashRegisterId,
        itemsCount: itemsCount,
        totalAmount: totalAmount,
      );
}

/// US-059: registra la alerta de stock bajo mostrada en el POS.
class LogLowStockAlertUseCase {
  final SaleRepository _repository;
  const LogLowStockAlertUseCase(this._repository);

  Future<Failure?> call({
    required String productId,
    required String productName,
    required int stock,
  }) =>
      _repository.logLowStockAlert(
        productId: productId,
        productName: productName,
        stock: stock,
      );
}
