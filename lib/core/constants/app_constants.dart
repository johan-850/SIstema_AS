/// Constantes globales de la aplicación Abarrotería Pro
abstract class AppConstants {
  // ── Roles ────────────────────────────────────────────────
  static const String roleAdmin = 'adminmaster';
  static const String roleCajero = 'cajero';

  // ── Paginación ───────────────────────────────────────────
  static const int pageSize = 20;

  // ── Tabla Supabase ────────────────────────────────────────
  static const String tableProfiles = 'profiles';
  static const String tableUserActivityLogs = 'user_activity_logs';

  // ── Edge Functions ────────────────────────────────────────
  static const String fnCreateCashier = 'create-cashier';
  static const String fnToggleCashierStatus = 'toggle-cashier-status';

  // ── Validación ────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxNameLength = 80;

  // ── Timeouts ──────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);
}
