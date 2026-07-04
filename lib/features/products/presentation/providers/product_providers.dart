// ============================================================
// lib/features/products/presentation/providers/product_providers.dart
// Providers de Riverpod para la Épica 3 — CRUD de Productos
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/product_remote_datasource.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/use_cases/product_use_cases.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../../core/errors/failures.dart';

// ── DI (Inyección de dependencias) ────────────────────────────

final productDatasourceProvider = Provider(
  (ref) => ProductRemoteDatasource(ref.read(supabaseClientProvider)),
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(ref.read(productDatasourceProvider)),
);

// ── Use cases ─────────────────────────────────────────────────

final getProductsUseCaseProvider = Provider(
  (ref) => GetProductsUseCase(ref.read(productRepositoryProvider)),
);

final getProductByBarcodeUseCaseProvider = Provider(
  (ref) => GetProductByBarcodeUseCase(ref.read(productRepositoryProvider)),
);

final createProductUseCaseProvider = Provider(
  (ref) => CreateProductUseCase(ref.read(productRepositoryProvider)),
);

final updateProductUseCaseProvider = Provider(
  (ref) => UpdateProductUseCase(ref.read(productRepositoryProvider)),
);

final toggleProductStatusUseCaseProvider = Provider(
  (ref) => ToggleProductStatusUseCase(ref.read(productRepositoryProvider)),
);

// ── US-014: Estado del listado de productos ───────────────────

/// Estado que maneja la lista de productos, búsqueda y paginación.
class ProductListState {
  final List<Product> products;
  final bool isLoading;
  final int currentPage;
  final Failure? failure;

  // Filtros activos
  final String? searchQuery;
  final String? filterCategory;
  final bool showInactive;

  const ProductListState({
    this.products = const [],
    this.isLoading = false,
    this.currentPage = 0,
    this.failure,
    this.searchQuery,
    this.filterCategory,
    this.showInactive = false,
  });

  /// True cuando hay filtros o búsqueda activa
  bool get hasActiveFilters =>
      (searchQuery != null && searchQuery!.isNotEmpty) ||
      filterCategory != null ||
      showInactive;

  ProductListState copyWith({
    List<Product>? products,
    bool? isLoading,
    int? currentPage,
    Failure? failure,
    String? searchQuery,
    String? filterCategory,
    bool? showInactive,
    bool clearFailure = false,
    bool clearFilters = false,
  }) =>
      ProductListState(
        products: products ?? this.products,
        isLoading: isLoading ?? this.isLoading,
        currentPage: currentPage ?? this.currentPage,
        failure: clearFailure ? null : (failure ?? this.failure),
        searchQuery:
            clearFilters ? null : (searchQuery ?? this.searchQuery),
        filterCategory:
            clearFilters ? null : (filterCategory ?? this.filterCategory),
        showInactive:
            clearFilters ? false : (showInactive ?? this.showInactive),
      );
}

class ProductListNotifier extends StateNotifier<ProductListState> {
  final GetProductsUseCase _getProducts;

  ProductListNotifier(this._getProducts) : super(const ProductListState()) {
    load();
  }

  /// Carga (o recarga) la lista con los filtros actuales.
  Future<void> load({int page = 0}) async {
    state = state.copyWith(isLoading: true, currentPage: page, clearFailure: true);

    final result = await _getProducts(
      query: state.searchQuery,
      category: state.filterCategory,
      activeOnly: !state.showInactive,
      page: page,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, failure: result.failure);
    } else {
      state = state.copyWith(isLoading: false, products: result.products);
    }
  }

  /// Buscar por texto (nombre o código de barras)
  Future<void> search(String query) async {
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
    await load();
  }

  /// Filtrar por categoría
  Future<void> filterByCategory(String? category) async {
    state = state.copyWith(filterCategory: category);
    await load();
  }

  /// Mostrar/ocultar productos inactivos
  Future<void> toggleShowInactive() async {
    state = state.copyWith(showInactive: !state.showInactive);
    await load();
  }

  /// Limpiar todos los filtros
  Future<void> clearFilters() async {
    state = state.copyWith(clearFilters: true);
    await load();
  }

  /// Recargar después de crear/editar un producto
  Future<void> refresh() => load(page: state.currentPage);
}

final productListProvider =
    StateNotifierProvider<ProductListNotifier, ProductListState>(
  (ref) => ProductListNotifier(ref.read(getProductsUseCaseProvider)),
);

// ── US-013 / US-015: Estado del formulario de producto ────────

/// Estado del formulario de creación/edición de producto.
class ProductFormState {
  final bool isLoading;
  final bool success;
  final Failure? failure;
  final Product? savedProduct;

  const ProductFormState({
    this.isLoading = false,
    this.success = false,
    this.failure,
    this.savedProduct,
  });

  ProductFormState copyWith({
    bool? isLoading,
    bool? success,
    Failure? failure,
    Product? savedProduct,
    bool clearFailure = false,
  }) =>
      ProductFormState(
        isLoading: isLoading ?? this.isLoading,
        success: success ?? this.success,
        failure: clearFailure ? null : (failure ?? this.failure),
        savedProduct: savedProduct ?? this.savedProduct,
      );
}

class ProductFormNotifier extends StateNotifier<ProductFormState> {
  final CreateProductUseCase _createUseCase;
  final UpdateProductUseCase _updateUseCase;

  ProductFormNotifier(this._createUseCase, this._updateUseCase)
      : super(const ProductFormState());

  /// US-013: Crear un nuevo producto
  Future<bool> create({
    String? barcode,
    required String name,
    String? description,
    required String category,
    required double price,
    required double costPrice,
    required int stock,
    required int minStock,
    required String unit,
    String? imageUrl,
    String? supplier,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _createUseCase(
      barcode: barcode,
      name: name,
      description: description,
      category: category,
      price: price,
      costPrice: costPrice,
      stock: stock,
      minStock: minStock,
      unit: unit,
      imageUrl: imageUrl,
      supplier: supplier,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, failure: result.failure);
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      success: true,
      savedProduct: result.product,
    );
    return true;
  }

  /// US-015: Actualizar un producto existente
  Future<bool> update({
    required String productId,
    String? barcode,
    String? name,
    String? description,
    String? category,
    double? price,
    double? costPrice,
    int? stock,
    int? minStock,
    String? unit,
    bool? isActive,
    String? imageUrl,
    String? supplier,
  }) async {
    state = state.copyWith(isLoading: true, clearFailure: true);

    final result = await _updateUseCase(
      productId: productId,
      barcode: barcode,
      name: name,
      description: description,
      category: category,
      price: price,
      costPrice: costPrice,
      stock: stock,
      minStock: minStock,
      unit: unit,
      isActive: isActive,
      imageUrl: imageUrl,
      supplier: supplier,
    );

    if (result.failure != null) {
      state = state.copyWith(isLoading: false, failure: result.failure);
      return false;
    }

    state = state.copyWith(
      isLoading: false,
      success: true,
      savedProduct: result.product,
    );
    return true;
  }

  /// Resetear estado del formulario
  void reset() => state = const ProductFormState();
}

final productFormProvider =
    StateNotifierProvider.autoDispose<ProductFormNotifier, ProductFormState>(
  (ref) => ProductFormNotifier(
    ref.read(createProductUseCaseProvider),
    ref.read(updateProductUseCaseProvider),
  ),
);
