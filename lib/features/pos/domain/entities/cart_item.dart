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

  /// US-059: stock mínimo configurado del producto — junto con
  /// [availableStock] y [quantity] permite calcular en vivo qué tan
  /// cerca está de agotarse a medida que cambia la cantidad en el carrito.
  final int minStock;

  /// US-029: descuento aplicado a este ítem, en pesos. Nunca supera
  /// [subtotal] — se valida tanto acá como en confirm_sale.
  final double discountAmount;

  const CartItem({
    required this.productId,
    required this.name,
    this.barcode,
    this.imageUrl,
    required this.unitPrice,
    required this.unit,
    required this.quantity,
    required this.availableStock,
    this.minStock = 0,
    this.discountAmount = 0,
  });

  /// Bruto: cantidad × precio, sin descuento. Mantiene el mismo
  /// significado que tenía antes de US-029 y que el que guarda
  /// sale_items.subtotal en la base de datos.
  double get subtotal => unitPrice * quantity;

  /// Lo que realmente aporta este ítem al total de la venta.
  double get netSubtotal => subtotal - discountAmount;

  /// Stock que quedaría del producto si se confirmara la venta con la
  /// cantidad actual del carrito.
  int get remainingStock => availableStock - quantity;

  CartItem copyWith({int? quantity, double? discountAmount}) => CartItem(
        productId: productId,
        name: name,
        barcode: barcode,
        imageUrl: imageUrl,
        unitPrice: unitPrice,
        unit: unit,
        quantity: quantity ?? this.quantity,
        availableStock: availableStock,
        minStock: minStock,
        discountAmount: discountAmount ?? this.discountAmount,
      );

  /// discountAmount va incluido a propósito: sin él, dos ítems que solo
  /// difieran en el descuento se considerarían iguales y la interfaz no
  /// se reconstruiría al cambiarlo.
  @override
  List<Object?> get props => [productId, quantity, discountAmount];
}
