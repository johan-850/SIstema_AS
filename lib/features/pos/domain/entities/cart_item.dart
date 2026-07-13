// ============================================================
// lib/features/pos/domain/entities/cart_item.dart
// Ítem del carrito de venta — EP-05 (US-025 a US-028, US-033)
// El carrito es 100% estado en memoria: no se persiste todavía
// (eso ocurre al implementar el cobro en S-06).
// ============================================================

import 'package:equatable/equatable.dart';

class CartItem extends Equatable {
  final String productId;
  final String name;
  final String? barcode;
  final String? imageUrl;
  final double unitPrice;
  final String unit;
  final int quantity;

  /// Stock disponible del producto al momento de agregarlo — límite
  /// para no dejar que el carrito supere lo que hay en existencia.
  final int availableStock;

  /// US-059: snapshot de si el producto ya estaba en (o bajo) su
  /// stock mínimo al momento de agregarlo — pinta el ícono de
  /// advertencia en el ítem del carrito.
  final bool isLowStock;

  const CartItem({
    required this.productId,
    required this.name,
    this.barcode,
    this.imageUrl,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
    required this.availableStock,
    this.isLowStock = false,
  });

  double get subtotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        productId: productId,
        name: name,
        barcode: barcode,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        unit: unit,
        quantity: quantity ?? this.quantity,
        availableStock: availableStock,
        isLowStock: isLowStock,
      );

  @override
  List<Object?> get props => [productId, quantity];
}
