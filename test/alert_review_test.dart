// Regla de "alerta revisada" del centro de alertas (US-061).
//
// Es la lógica que decide si una alerta desaparece o vuelve a aparecer.
// Equivocarse acá significa esconderle al AdminMaster un problema que
// empeoró, que es justo lo contrario de para lo que sirve la pantalla.

import 'package:flutter_test/flutter_test.dart';
import 'package:abarroteria_pro/features/alerts/domain/entities/alert.dart';

Alert _alerta(AlertType tipo, {double? contexto}) => Alert(
      type: tipo,
      key: 'k1',
      title: 'Alerta',
      detail: 'Detalle',
      date: DateTime(2026),
      severity: AlertSeverity.warning,
      contextValue: contexto,
    );

void main() {
  group('sin revisión previa', () {
    test('ninguna alerta cuenta como revisada', () {
      for (final tipo in AlertType.values) {
        expect(isAlertReviewed(_alerta(tipo, contexto: 5), null), isFalse);
      }
    });
  });

  group('cuadres y gastos son hechos inmutables', () {
    test('una vez revisados, quedan revisados', () {
      final revision = (alertKey: 'k1', type: AlertType.cuadre, contextValue: null);
      expect(isAlertReviewed(_alerta(AlertType.cuadre), revision), isTrue);

      final revisionGasto = (alertKey: 'k1', type: AlertType.gasto, contextValue: null);
      expect(isAlertReviewed(_alerta(AlertType.gasto), revisionGasto), isTrue);
    });
  });

  group('el stock es una condición viva', () {
    test('sigue revisada si el stock no cambió', () {
      final revision = (alertKey: 'k1', type: AlertType.stock, contextValue: 3.0);
      expect(isAlertReviewed(_alerta(AlertType.stock, contexto: 3), revision), isTrue);
    });

    test('sigue revisada si el stock mejoró', () {
      final revision = (alertKey: 'k1', type: AlertType.stock, contextValue: 3.0);
      expect(isAlertReviewed(_alerta(AlertType.stock, contexto: 8), revision), isTrue);
    });

    test('VUELVE a aparecer si el stock empeoró', () {
      // Se revisó con 3 unidades; ahora queda 1. La situación es peor
      // que cuando el admin la miró, así que tiene que volver a verla.
      final revision = (alertKey: 'k1', type: AlertType.stock, contextValue: 3.0);
      expect(isAlertReviewed(_alerta(AlertType.stock, contexto: 1), revision), isFalse);
    });

    test('vuelve a aparecer al agotarse por completo', () {
      final revision = (alertKey: 'k1', type: AlertType.stock, contextValue: 2.0);
      expect(isAlertReviewed(_alerta(AlertType.stock, contexto: 0), revision), isFalse);
    });

    test('sin contexto guardado se respeta la revisión', () {
      // Caso de datos viejos: no hay con qué comparar, así que no se
      // molesta al admin repitiendo una alerta que ya marcó.
      final revision = (alertKey: 'k1', type: AlertType.stock, contextValue: null);
      expect(isAlertReviewed(_alerta(AlertType.stock, contexto: 1), revision), isTrue);
    });
  });
}
