// Reglas del semáforo de stock (US-059), la lógica de negocio pura
// menos obvia del proyecto: el margen del 1.5x y el caso especial de
// minStock = 0 no se adivinan leyendo el nombre de la función.

import 'package:flutter_test/flutter_test.dart';
import 'package:abarroteria_pro/core/utils/stock_tier.dart';

void main() {
  group('stockTierFor con un mínimo configurado (minStock = 10)', () {
    test('agotado es crítico', () {
      expect(stockTierFor(remainingStock: 0, minStock: 10), StockTier.critical);
    });

    test('justo en el mínimo es crítico, no "cerca"', () {
      expect(stockTierFor(remainingStock: 10, minStock: 10), StockTier.critical);
    });

    test('una unidad por encima del mínimo entra en "cerca"', () {
      expect(stockTierFor(remainingStock: 11, minStock: 10), StockTier.near);
    });

    test('el límite del margen del 50% sigue siendo "cerca"', () {
      // ceil(10 * 1.5) = 15
      expect(stockTierFor(remainingStock: 15, minStock: 10), StockTier.near);
    });

    test('una unidad por encima del margen ya es normal', () {
      expect(stockTierFor(remainingStock: 16, minStock: 10), StockTier.normal);
    });
  });

  group('stockTierFor redondea el margen hacia arriba (minStock = 5)', () {
    // ceil(5 * 1.5) = ceil(7.5) = 8 — el .5 redondea hacia arriba,
    // así que 8 todavía es "cerca".
    test('8 es "cerca" porque el margen se redondea hacia arriba', () {
      expect(stockTierFor(remainingStock: 8, minStock: 5), StockTier.near);
    });

    test('9 ya es normal', () {
      expect(stockTierFor(remainingStock: 9, minStock: 5), StockTier.normal);
    });
  });

  group('stockTierFor sin mínimo configurado (minStock = 0)', () {
    test('agotado es crítico', () {
      expect(stockTierFor(remainingStock: 0, minStock: 0), StockTier.critical);
    });

    test('no existe zona "cerca": una unidad ya es normal', () {
      expect(stockTierFor(remainingStock: 1, minStock: 0), StockTier.normal);
    });
  });

  group('stockTierFor con stock negativo', () {
    test('un sobrevendido es crítico, no normal', () {
      // Puede pasar si el carrito pide más de lo que hay disponible.
      expect(stockTierFor(remainingStock: -3, minStock: 10), StockTier.critical);
      expect(stockTierFor(remainingStock: -1, minStock: 0), StockTier.critical);
    });
  });
}
