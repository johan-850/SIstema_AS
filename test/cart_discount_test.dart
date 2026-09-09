// Aritmética de descuentos del carrito (US-029).
//
// Es la lógica donde un error se paga en dinero real: si el neto sale
// mal, el cajero cobra de menos y el cuadre de caja lo culpa a él.
// Lógica pura sobre el notifier, sin Supabase.

import 'package:flutter_test/flutter_test.dart';
import 'package:abarroteria_pro/features/pos/presentation/providers/cart_providers.dart';
import 'package:abarroteria_pro/features/products/domain/entities/product.dart';

Product _producto({
  String id = 'p1',
  String nombre = 'Arroz',
  double precio = 1000,
  int stock = 50,
}) =>
    Product(
      id: id,
      name: nombre,
      category: 'General',
      price: precio,
      costPrice: precio / 2,
      stock: stock,
      minStock: 5,
      unit: 'unidad',
      isActive: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('sin descuentos', () {
    test('el neto es igual al bruto', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 3);
      expect(c.state.grossAmount, 3000);
      expect(c.state.discountTotal, 0);
      expect(c.state.totalAmount, 3000);
      expect(c.state.hasDiscount, isFalse);
    });
  });

  group('descuento por ítem', () {
    test('resta del neto sin tocar el bruto', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 3);
      c.setItemDiscount('p1', 500);

      expect(c.state.grossAmount, 3000, reason: 'el bruto no cambia');
      expect(c.state.itemDiscountTotal, 500);
      expect(c.state.totalAmount, 2500);
    });

    test('el subtotal del ítem sigue siendo bruto y netSubtotal el neto', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 2);
      c.setItemDiscount('p1', 300);

      final item = c.state.items.first;
      expect(item.subtotal, 2000);
      expect(item.netSubtotal, 1700);
    });

    test('se recorta al subtotal si se pasa, y avisa', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 1);
      c.setItemDiscount('p1', 5000);

      expect(c.state.items.first.discountAmount, 1000);
      expect(c.state.totalAmount, 0);
      expect(c.state.warningMessage, isNotNull);
    });

    test('ignora montos negativos', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 1);
      c.setItemDiscount('p1', -100);
      expect(c.state.items.first.discountAmount, 0);
    });
  });

  group('descuento global', () {
    test('resta del neto', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 4);
      c.setGlobalDiscount(1500);

      expect(c.state.grossAmount, 4000);
      expect(c.state.totalAmount, 2500);
    });

    test('no puede dejar el total negativo: se recorta al máximo', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 2);
      c.setGlobalDiscount(9999);

      expect(c.state.globalDiscount, 2000);
      expect(c.state.totalAmount, 0);
      expect(c.state.warningMessage, isNotNull);
    });
  });

  group('descuento por ítem y global combinados', () {
    test('se suman ambos', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 10); // 10.000
      c.setItemDiscount('p1', 1000);
      c.setGlobalDiscount(500);

      expect(c.state.itemDiscountTotal, 1000);
      expect(c.state.globalDiscount, 500);
      expect(c.state.discountTotal, 1500);
      expect(c.state.totalAmount, 8500);
    });

    test('el global no puede pasarse de lo que queda tras el de ítem', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 2); // 2.000
      c.setItemDiscount('p1', 1500);
      c.setGlobalDiscount(1000); // solo quedan 500

      expect(c.state.globalDiscount, 500);
      expect(c.state.totalAmount, 0);
    });
  });

  group('el porcentaje decide si hace falta PIN', () {
    test('calcula el porcentaje sobre el bruto', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 10); // 10.000
      c.setGlobalDiscount(1500);
      expect(c.state.discountPercent, 15);
    });

    test('carrito vacío no divide por cero', () {
      expect(CartNotifier().state.discountPercent, 0);
    });
  });

  group('los descuentos se reajustan al cambiar el carrito', () {
    test('bajar la cantidad recorta el descuento del ítem', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 5); // 5.000
      c.setItemDiscount('p1', 4000);

      c.updateQuantity('p1', 1); // ahora vale 1.000
      expect(c.state.items.first.discountAmount, 1000,
          reason: 'un descuento mayor al nuevo subtotal dejaría el total negativo');
      expect(c.state.totalAmount, 0);
    });

    test('quitar un ítem recorta el descuento global', () {
      final c = CartNotifier()
        ..addProduct(_producto(id: 'p1'), quantity: 5) // 5.000
        ..addProduct(_producto(id: 'p2', nombre: 'Aceite'), quantity: 5); // 5.000
      c.setGlobalDiscount(8000);
      expect(c.state.globalDiscount, 8000);

      c.removeItem('p2'); // quedan 5.000
      expect(c.state.globalDiscount, 5000);
      expect(c.state.totalAmount, 0);
    });

    test('vaciar el carrito borra los descuentos', () {
      final c = CartNotifier()..addProduct(_producto(), quantity: 2);
      c.setGlobalDiscount(500);
      c.clear();

      expect(c.state.globalDiscount, 0);
      expect(c.state.totalAmount, 0);
      expect(c.state.hasDiscount, isFalse);
    });
  });

  group('CartItem compara por descuento', () {
    test('dos ítems que solo difieren en el descuento NO son iguales', () {
      // Si props ignorara discountAmount, la interfaz no se reconstruiría
      // al cambiar un descuento y el cajero vería el valor viejo.
      final c = CartNotifier()..addProduct(_producto(), quantity: 1);
      final antes = c.state.items.first;
      c.setItemDiscount('p1', 200);
      final despues = c.state.items.first;

      expect(antes == despues, isFalse);
    });
  });
}
