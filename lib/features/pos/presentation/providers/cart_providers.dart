// ============================================================
// lib/features/pos/presentation/providers/cart_providers.dart
// Estado del carrito de venta — US-025 a US-028
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/cart_item.dart';
import '../../../products/domain/entities/product.dart';

/// US-059: info mínima para mostrar el banner de stock bajo y
/// registrar la alerta — se resuelve en la capa de presentación
/// (el notifier no toca la red).
typedef LowStockAlert = ({String productId, String productName, int stock});

class CartState {
  final List<CartItem> items;
  final String? warningMessage;
  final LowStockAlert? lowStockAlert;

  /// US-029: descuento aplicado a la venta completa, en pesos. Es
  /// independiente de los descuentos por ítem y se suma a ellos.
  final double globalDiscount;

  const CartState({
    this.items = const [],
    this.warningMessage,
    this.lowStockAlert,
    this.globalDiscount = 0,
  });

  int get totalItems => items.fold(0, (sum, i) => sum + i.quantity);

  /// Suma de los subtotales brutos, sin ningún descuento.
  double get grossAmount => items.fold(0.0, (sum, i) => sum + i.subtotal);

  /// Suma de los descuentos por ítem (sin el global).
  double get itemDiscountTotal => items.fold(0.0, (sum, i) => sum + i.discountAmount);

  /// Todos los descuentos juntos.
  double get discountTotal => itemDiscountTotal + globalDiscount;

  /// Lo que paga el cliente. Coincide con lo que confirm_sale guarda
  /// en sales.total, que es lo que suma el cuadre de caja.
  double get totalAmount => grossAmount - discountTotal;

  /// Cuánto más se puede descontar globalmente sin dejar el total negativo.
  double get maxGlobalDiscount => grossAmount - itemDiscountTotal;

  /// Porcentaje de descuento sobre el bruto — determina si hace falta PIN.
  double get discountPercent => grossAmount <= 0 ? 0 : (discountTotal / grossAmount) * 100;

  bool get hasDiscount => discountTotal > 0;
  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    String? warningMessage,
    bool clearWarning = false,
    LowStockAlert? lowStockAlert,
    bool clearLowStockAlert = false,
    double? globalDiscount,
  }) =>
      CartState(
        items: items ?? this.items,
        warningMessage: clearWarning ? null : (warningMessage ?? this.warningMessage),
        lowStockAlert: clearLowStockAlert ? null : (lowStockAlert ?? this.lowStockAlert),
        globalDiscount: globalDiscount ?? this.globalDiscount,
      );
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  /// US-025/US-026/US-033: agrega un producto (o incrementa su cantidad si
  /// ya está en el carrito). Nunca deja superar el stock disponible ni
  /// agregar productos agotados — es la única validación de negocio que
  /// tiene sentido hacer client-side hasta que exista el cobro (S-06).
  void addProduct(Product product, {int quantity = 1}) {
    if (product.isOutOfStock) {
      state = state.copyWith(warningMessage: '"${product.name}" está agotado.');
      return;
    }

    final lowStockAlert = product.isLowStock
        ? (productId: product.id, productName: product.name, stock: product.stock)
        : null;

    final index = state.items.indexWhere((i) => i.productId == product.id);

    if (index == -1) {
      final qty = quantity > product.stock ? product.stock : quantity;
      final item = CartItem(
        productId: product.id,
        name: product.name,
        barcode: product.barcode,
        imageUrl: product.imageUrl,
        unitPrice: product.price,
        unit: product.unit,
        quantity: qty,
        availableStock: product.stock,
        minStock: product.minStock,
      );
      state = state.copyWith(
        items: [...state.items, item],
        clearWarning: true,
        lowStockAlert: lowStockAlert,
        clearLowStockAlert: lowStockAlert == null,
      );
      return;
    }

    final existing = state.items[index];
    final desiredQty = existing.quantity + quantity;

    if (desiredQty > existing.availableStock) {
      state = state.copyWith(
        items: _replaceQuantity(existing.productId, existing.availableStock),
        warningMessage:
            'Solo hay ${existing.availableStock} ${existing.unit} disponibles de "${existing.name}".',
      );
      return;
    }

    state = state.copyWith(
      items: _replaceQuantity(existing.productId, desiredQty),
      clearWarning: true,
      lowStockAlert: lowStockAlert,
      clearLowStockAlert: lowStockAlert == null,
    );
  }

  /// US-028: ajusta la cantidad de un ítem ya en el carrito.
  /// [quantity] debe ser > 0 — bajar a 0 se maneja en la UI (confirmación
  /// antes de llamar [removeItem]), no en el notifier.
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) return;

    final index = state.items.indexWhere((i) => i.productId == productId);
    if (index == -1) return;
    final item = state.items[index];

    if (quantity > item.availableStock) {
      state = state.copyWith(
        items: _replaceQuantity(productId, item.availableStock),
        warningMessage:
            'Solo hay ${item.availableStock} ${item.unit} disponibles de "${item.name}".',
      );
      _clampGlobalDiscount();
      return;
    }

    state = state.copyWith(items: _replaceQuantity(productId, quantity), clearWarning: true);
    _clampGlobalDiscount();
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((i) => i.productId != productId).toList(),
      clearWarning: true,
    );
    _clampGlobalDiscount();
  }

  void clear() => state = const CartState();

  /// US-029: descuento en pesos sobre un ítem. Si supera su subtotal se
  /// recorta al máximo posible y se avisa — mismo criterio que ya se usa
  /// al pasarse del stock disponible.
  void setItemDiscount(String productId, double amount) {
    final index = state.items.indexWhere((i) => i.productId == productId);
    if (index == -1) return;
    final item = state.items[index];

    if (amount < 0) return;

    if (amount > item.subtotal) {
      state = state.copyWith(
        items: _replaceDiscount(productId, item.subtotal),
        warningMessage:
            'El descuento de "${item.name}" no puede superar su subtotal (\$${item.subtotal.toStringAsFixed(0)}).',
      );
      _clampGlobalDiscount();
      return;
    }

    state = state.copyWith(items: _replaceDiscount(productId, amount), clearWarning: true);
    _clampGlobalDiscount();
  }

  /// US-029: descuento en pesos sobre el total de la venta. No puede
  /// superar lo que queda tras los descuentos por ítem, para que el total
  /// nunca quede negativo (confirm_sale valida lo mismo del lado servidor).
  void setGlobalDiscount(double amount) {
    if (amount < 0) return;

    final max = state.maxGlobalDiscount;

    if (amount > max) {
      state = state.copyWith(
        globalDiscount: max < 0 ? 0 : max,
        warningMessage:
            'El descuento no puede superar el total de la venta (\$${(max < 0 ? 0 : max).toStringAsFixed(0)}).',
      );
      return;
    }

    state = state.copyWith(globalDiscount: amount, clearWarning: true);
  }

  /// Tras quitar un ítem o bajar una cantidad, el descuento global puede
  /// haber quedado por encima de lo que ahora vale la venta.
  void _clampGlobalDiscount() {
    final max = state.maxGlobalDiscount;
    if (state.globalDiscount > max) {
      state = state.copyWith(globalDiscount: max < 0 ? 0 : max);
    }
  }

  /// Al bajar la cantidad, un descuento por ítem ya aplicado puede quedar
  /// por encima del nuevo subtotal.
  List<CartItem> _replaceQuantity(String productId, int quantity) => [
        for (final i in state.items)
          if (i.productId == productId)
            i.copyWith(
              quantity: quantity,
              discountAmount: i.discountAmount > (i.unitPrice * quantity)
                  ? i.unitPrice * quantity
                  : i.discountAmount,
            )
          else
            i,
      ];

  List<CartItem> _replaceDiscount(String productId, double amount) => [
        for (final i in state.items)
          i.productId == productId ? i.copyWith(discountAmount: amount) : i,
      ];
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);
