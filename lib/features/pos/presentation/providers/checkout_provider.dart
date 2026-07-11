// ============================================================
// lib/features/pos/presentation/providers/checkout_provider.dart
// Estado del formulario de cobro — US-030, US-031
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/sale_remote_datasource.dart';
import '../../data/repositories/sale_repository_impl.dart';
import '../../domain/entities/cart_item.dart';
import '../../domain/entities/sale.dart';
import '../../domain/repositories/sale_repository.dart';
import '../../domain/use_cases/sale_use_cases.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/errors/failures.dart';

// ── DI ──────────────────────────────────────────────────────────

final saleDatasourceProvider = Provider(
  (ref) => SaleRemoteDatasource(ref.read(supabaseClientProvider)),
);

final saleRepositoryProvider = Provider<SaleRepository>(
  (ref) => SaleRepositoryImpl(ref.read(saleDatasourceProvider)),
);

final confirmSaleUseCaseProvider = Provider(
  (ref) => ConfirmSaleUseCase(ref.read(saleRepositoryProvider)),
);

// ── Estado del checkout ─────────────────────────────────────────

class CheckoutState {
  final String paymentMethod; // 'efectivo' | 'transferencia' | 'mixto'
  final double? cashAmount;
  final double? transferAmount;
  final bool isLoading;
  final Failure? failure;
  final Sale? sale;

  const CheckoutState({
    this.paymentMethod = 'efectivo',
    this.cashAmount,
    this.transferAmount,
    this.isLoading = false,
    this.failure,
    this.sale,
  });

  CheckoutState copyWith({
    String? paymentMethod,
    double? cashAmount,
    double? transferAmount,
    bool? isLoading,
    Failure? failure,
    Sale? sale,
    bool clearFailure = false,
  }) =>
      CheckoutState(
        paymentMethod: paymentMethod ?? this.paymentMethod,
        cashAmount: cashAmount ?? this.cashAmount,
        transferAmount: transferAmount ?? this.transferAmount,
        isLoading: isLoading ?? this.isLoading,
        failure: clearFailure ? null : (failure ?? this.failure),
        sale: sale ?? this.sale,
      );
}

class CheckoutNotifier extends StateNotifier<CheckoutState> {
  final ConfirmSaleUseCase _confirmSale;
  CheckoutNotifier(this._confirmSale) : super(const CheckoutState());

  void setPaymentMethod(String method) {
    state = CheckoutState(paymentMethod: method); // resetea montos al cambiar de método
  }

  void setCashAmount(double? amount) => state = state.copyWith(cashAmount: amount, clearFailure: true);

  void setTransferAmount(double? amount) =>
      state = state.copyWith(transferAmount: amount, clearFailure: true);

  Future<bool> confirm({required String cashRegisterId, required List<CartItem> items}) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _confirmSale(
      cashRegisterId: cashRegisterId,
      paymentMethod: state.paymentMethod,
      cashAmount: state.cashAmount,
      transferAmount: state.transferAmount,
      items: items,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, failure: result.failure);
      return false;
    }

    state = state.copyWith(isLoading: false, sale: result.sale);
    return true;
  }
}

final checkoutProvider = StateNotifierProvider.autoDispose<CheckoutNotifier, CheckoutState>(
  (ref) => CheckoutNotifier(ref.read(confirmSaleUseCaseProvider)),
);
