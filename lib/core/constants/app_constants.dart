/// Constantes globales de la aplicación Abarrotería Pro
abstract class AppConstants {
  // ── Roles ────────────────────────────────────────────────
  static const String roleAdmin   = 'adminmaster';
  static const String roleCajero  = 'cajero';

  // ── Paginación ───────────────────────────────────────────
  static const int pageSize = 20;

  // ── Tablas Supabase — EP-01 ───────────────────────────────
  static const String tableProfiles          = 'profiles';
  static const String tableUserActivityLogs  = 'user_activity_logs';

  // ── Tablas Supabase — EP-02 ───────────────────────────────
  static const String tableCashRegisters     = 'cash_registers';
  static const String tableCashMovements     = 'cash_movements';

  // ── Edge Functions ────────────────────────────────────────
  static const String fnCreateCashier        = 'create-cashier';
  static const String fnToggleCashierStatus  = 'toggle-cashier-status';

  // ── Validación ────────────────────────────────────────────
  static const int minPasswordLength = 6;
  static const int maxNameLength     = 80;
  static const int maxNotesLength    = 300;

  // ── Timeouts ──────────────────────────────────────────────
  static const Duration requestTimeout = Duration(seconds: 15);

  // ── Denominaciones COP ────────────────────────────────────
  /// Monedas (llave → valor en pesos)
  static const Map<String, int> coinDenominations = {
    'coin_50':   50,
    'coin_100':  100,
    'coin_200':  200,
    'coin_500':  500,
    'coin_1000': 1000,
  };

  /// Billetes (llave → valor en pesos)
  static const Map<String, int> billDenominations = {
    'bill_1000':   1000,
    'bill_2000':   2000,
    'bill_5000':   5000,
    'bill_10000':  10000,
    'bill_20000':  20000,
    'bill_50000':  50000,
    'bill_100000': 100000,
  };
}

