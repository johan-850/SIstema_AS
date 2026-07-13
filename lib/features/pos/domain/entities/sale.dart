// ============================================================
// lib/features/pos/domain/entities/sale.dart
// Venta confirmada — US-030, US-031
// ============================================================

import 'package:equatable/equatable.dart';

class Sale extends Equatable {
  final String id;
  final double total;
  final String paymentMethod; // 'efectivo' | 'transferencia' | 'mixto'
  final double? cashAmount;
  final double? transferAmount;
  final double? changeAmount;
  final String? receiptPhotoUrl;
  final DateTime createdAt;

  const Sale({
    required this.id,
    required this.total,
    required this.paymentMethod,
    this.cashAmount,
    this.transferAmount,
    this.changeAmount,
    this.receiptPhotoUrl,
    required this.createdAt,
  });

  bool get isCash => paymentMethod == 'efectivo';
  bool get isMixed => paymentMethod == 'mixto';
  bool get isTransfer => paymentMethod == 'transferencia';

  @override
  List<Object?> get props => [id];
}
