// ============================================================
// lib/features/settings/presentation/providers/store_settings_providers.dart
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/store_settings_remote_datasource.dart';
import '../../data/repositories/store_settings_repository_impl.dart';
import '../../domain/entities/store_settings.dart';
import '../../domain/repositories/store_settings_repository.dart';
import '../../domain/use_cases/store_settings_use_cases.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

// ── DI ──────────────────────────────────────────────────────────

final storeSettingsDatasourceProvider = Provider(
  (ref) => StoreSettingsRemoteDatasource(ref.read(supabaseClientProvider)),
);

final storeSettingsRepositoryProvider = Provider<StoreSettingsRepository>(
  (ref) => StoreSettingsRepositoryImpl(ref.read(storeSettingsDatasourceProvider)),
);

final getStoreSettingsUseCaseProvider = Provider(
  (ref) => GetStoreSettingsUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final updateQrImageUseCaseProvider = Provider(
  (ref) => UpdateQrImageUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final removeQrImageUseCaseProvider = Provider(
  (ref) => RemoveQrImageUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final updateExpenseSettingsUseCaseProvider = Provider(
  (ref) => UpdateExpenseSettingsUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final updateCashDiffCommentThresholdUseCaseProvider = Provider(
  (ref) => UpdateCashDiffCommentThresholdUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final updateWeeklyReportSettingsUseCaseProvider = Provider(
  (ref) => UpdateWeeklyReportSettingsUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final sendWeeklyReportNowUseCaseProvider = Provider(
  (ref) => SendWeeklyReportNowUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final updateDiscountThresholdUseCaseProvider = Provider(
  (ref) => UpdateDiscountThresholdUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final setDiscountPinUseCaseProvider = Provider(
  (ref) => SetDiscountPinUseCase(ref.read(storeSettingsRepositoryProvider)),
);

final hasDiscountPinUseCaseProvider = Provider(
  (ref) => HasDiscountPinUseCase(ref.read(storeSettingsRepositoryProvider)),
);

/// US-029: si hay PIN configurado. Se relee con `ref.invalidate` tras
/// guardarlo desde Configuración.
final hasDiscountPinProvider = FutureProvider<bool>((ref) async {
  final result = await ref.read(hasDiscountPinUseCaseProvider)();
  return result.hasPin;
});

// ── Lectura ─────────────────────────────────────────────────────

/// Configuración del negocio (hoy: solo el QR de pago). Se relee con
/// `ref.invalidate(storeSettingsProvider)` después de subir/quitar el QR
/// desde la pantalla de configuración — no cambia con frecuencia como
/// para justificar una suscripción realtime.
final storeSettingsProvider = FutureProvider<StoreSettings?>((ref) async {
  final result = await ref.read(getStoreSettingsUseCaseProvider)();
  return result.settings;
});
