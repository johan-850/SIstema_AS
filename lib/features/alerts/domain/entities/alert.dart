// ============================================================
// lib/features/alerts/domain/entities/alert.dart
// Alerta del centro de alertas — US-061
//
// Una alerta no es una fila de la base de datos: se deriva de
// productos, cuadres de caja y gastos. Lo único persistido es cuáles
// ya revisó el AdminMaster (tabla alert_reviews).
// ============================================================

import 'package:equatable/equatable.dart';

enum AlertType { stock, cuadre, gasto }

extension AlertTypeX on AlertType {
  String get value => switch (this) {
        AlertType.stock => 'stock',
        AlertType.cuadre => 'cuadre',
        AlertType.gasto => 'gasto',
      };

  String get label => switch (this) {
        AlertType.stock => 'Stock',
        AlertType.cuadre => 'Cuadres',
        AlertType.gasto => 'Gastos',
      };

  static AlertType fromValue(String v) => switch (v) {
        'cuadre' => AlertType.cuadre,
        'gasto' => AlertType.gasto,
        _ => AlertType.stock,
      };
}

/// Qué tan grave es. Se usa para el color y para ordenar.
enum AlertSeverity { critical, warning }

class Alert extends Equatable {
  final AlertType type;

  /// id de la fila que originó la alerta: product_id, cash_register_id
  /// o expense_id. Junto con [type] identifica la alerta de forma estable.
  final String key;

  final String title;
  final String detail;
  final DateTime date;
  final AlertSeverity severity;
  final bool isReviewed;

  /// Solo en alertas de stock: la existencia actual del producto. Es lo
  /// que se guarda al revisar, para poder volver a avisar si empeora.
  final double? contextValue;

  const Alert({
    required this.type,
    required this.key,
    required this.title,
    required this.detail,
    required this.date,
    required this.severity,
    this.isReviewed = false,
    this.contextValue,
  });

  Alert copyWith({bool? isReviewed}) => Alert(
        type: type,
        key: key,
        title: title,
        detail: detail,
        date: date,
        severity: severity,
        isReviewed: isReviewed ?? this.isReviewed,
        contextValue: contextValue,
      );

  @override
  List<Object?> get props => [type, key, isReviewed];
}

/// Lo que se sabe de una revisión ya guardada.
typedef AlertReview = ({String alertKey, AlertType type, double? contextValue});

/// Decide si una alerta sigue mereciendo mostrarse dado lo ya revisado.
///
/// La regla no es igual para las tres categorías, y esa es justamente la
/// parte que hay que acertar:
///
/// - **Cuadres y gastos** son hechos inmutables: una vez cerrado el
///   cuadre su diferencia no cambia, y un gasto registrado no cambia de
///   monto. Revisado una vez, revisado para siempre.
/// - **El stock bajo es una condición viva.** Si el admin revisó
///   "quedan 3" y ahora quedan 1, esconderlo sería un error: la
///   situación empeoró. Por eso la alerta reaparece si el stock cayó por
///   debajo del valor que tenía al revisarse.
bool isAlertReviewed(Alert alert, AlertReview? review) {
  if (review == null) return false;

  if (alert.type != AlertType.stock) return true;

  // Sin contexto guardado no hay con qué comparar: se respeta la revisión.
  final reviewedAt = review.contextValue;
  final current = alert.contextValue;
  if (reviewedAt == null || current == null) return true;

  // Empeoró desde que se revisó: vuelve a avisar.
  return current >= reviewedAt;
}
