// ============================================================
// lib/features/settings/domain/entities/store_settings.dart
// Configuración general del negocio (singleton) — QR de pago
// ============================================================

import 'package:equatable/equatable.dart';

class StoreSettings extends Equatable {
  final String? qrImageUrl;

  const StoreSettings({this.qrImageUrl});

  bool get hasQrImage => qrImageUrl != null && qrImageUrl!.isNotEmpty;

  @override
  List<Object?> get props => [qrImageUrl];
}
