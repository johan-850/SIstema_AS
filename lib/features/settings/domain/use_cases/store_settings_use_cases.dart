// ============================================================
// lib/features/settings/domain/use_cases/store_settings_use_cases.dart
// ============================================================

import 'dart:typed_data';

import '../repositories/store_settings_repository.dart';

class GetStoreSettingsUseCase {
  final StoreSettingsRepository _repository;
  const GetStoreSettingsUseCase(this._repository);

  Future<StoreSettingsResult> call() => _repository.getSettings();
}

/// Sube una nueva imagen de QR y la guarda como configuración vigente.
class UpdateQrImageUseCase {
  final StoreSettingsRepository _repository;
  const UpdateQrImageUseCase(this._repository);

  Future<StoreSettingsResult> call(Uint8List bytes, String fileExt) =>
      _repository.updateQrImage(bytes, fileExt);
}

/// Quita el QR configurado.
class RemoveQrImageUseCase {
  final StoreSettingsRepository _repository;
  const RemoveQrImageUseCase(this._repository);

  Future<StoreSettingsResult> call(String currentUrl) => _repository.removeQrImage(currentUrl);
}
