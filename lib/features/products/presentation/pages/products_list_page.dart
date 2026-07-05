// ============================================================
// lib/features/products/presentation/pages/products_list_page.dart
// US-014: Listado de productos con búsqueda y filtros
// US-016: Desactivar/reactivar productos
// Diseño: Glassmorphism / Neumorphism dark
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/product_providers.dart';
import '../../domain/entities/product.dart';

class ProductsListPage extends ConsumerStatefulWidget {
  const ProductsListPage({super.key});

  @override
  ConsumerState<ProductsListPage> createState() => _ProductsListPageState();
}

class _ProductsListPageState extends ConsumerState<ProductsListPage> {
  final _searchController = TextEditingController();
  final _currencyFmt = NumberFormat.currency(locale: 'es_CO', symbol: '\$', decimalDigits: 0);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productListProvider);
    final notifier = ref.read(productListProvider.notifier);

    // Escuchar errores
    ref.listen<ProductListState>(productListProvider, (_, next) {
      if (next.failure != null) {
        AppSnackbar.error(context, next.failure!.message);
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Inventario'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/admin'),
        ),
        actions: [
          // Botón de filtro de categoría
          IconButton(
            icon: Badge(
              isLabelVisible: state.filterCategory != null,
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.filter_list_rounded),
            ),
            onPressed: () => _showCategoryFilter(context, notifier, state),
          ),
          // Toggle productos inactivos
          IconButton(
            icon: Icon(
              state.showInactive
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: state.showInactive ? AppColors.warning : null,
            ),
            tooltip: state.showInactive ? 'Ocultar inactivos' : 'Mostrar inactivos',
            onPressed: () => notifier.toggleShowInactive(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Barra de búsqueda ──────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _SearchBar(
              controller: _searchController,
              onChanged: (q) => notifier.search(q),
              onClear: () {
                _searchController.clear();
                notifier.search('');
              },
            ),
          ),

          // ── Indicador de filtros activos ─────────────────────
          if (state.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _ActiveFiltersChip(
                category: state.filterCategory,
                showInactive: state.showInactive,
                onClear: () {
                  _searchController.clear();
                  notifier.clearFilters();
                },
              ),
            ),

          // ── Lista de productos ──────────────────────────────
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : state.products.isEmpty
                    ? _EmptyState(
                        hasFilters: state.hasActiveFilters,
                        onClearFilters: () {
                          _searchController.clear();
                          notifier.clearFilters();
                        },
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => notifier.refresh(),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: state.products.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, i) => _ProductCard(
                            product: state.products[i],
                            currencyFmt: _currencyFmt,
                            onTap: () => context.go('/admin/products/edit/${state.products[i].id}'),
                          ),
                        ),
                      ),
          ),
        ],
      ),

      // ── FAB: Crear producto ─────────────────────────────────
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/admin/products/new'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo Producto'),
      ),
    );
  }

  /// Bottom sheet para seleccionar categoría
  void _showCategoryFilter(
    BuildContext context,
    ProductListNotifier notifier,
    ProductListState state,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Icon(Icons.category_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtrar por Categoría',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (state.filterCategory != null)
                    TextButton(
                      onPressed: () {
                        notifier.filterByCategory(null);
                        Navigator.pop(context);
                      },
                      child: const Text('Limpiar'),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...AppConstants.productCategories.map((cat) => ListTile(
                  leading: Icon(
                    state.filterCategory == cat
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: state.filterCategory == cat
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  title: Text(cat, style: const TextStyle(color: AppColors.textPrimary)),
                  dense: true,
                  onTap: () {
                    notifier.filterByCategory(cat);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }
}

// ── Search Bar ────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBar({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o código de barras...',
          hintStyle: const TextStyle(color: AppColors.textDisabled),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

// ── Active Filters Chip ───────────────────────────────────────

class _ActiveFiltersChip extends StatelessWidget {
  final String? category;
  final bool showInactive;
  final VoidCallback onClear;

  const _ActiveFiltersChip({
    this.category,
    this.showInactive = false,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final labels = <String>[];
    if (category != null) labels.add(category!);
    if (showInactive) labels.add('Inactivos visibles');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.filter_alt_rounded, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              labels.join(' · '),
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          GestureDetector(
            onTap: onClear,
            child: const Icon(Icons.close_rounded, size: 16, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

// ── Product Card ──────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final NumberFormat currencyFmt;
  final VoidCallback onTap;

  const _ProductCard({
    required this.product,
    required this.currencyFmt,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: product.isActive
              ? AppColors.surfaceCard
              : AppColors.surfaceCard.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: product.isOutOfStock
                ? AppColors.stockCritical.withValues(alpha: 0.4)
                : product.isLowStock
                    ? AppColors.stockWarning.withValues(alpha: 0.3)
                    : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            // ── Indicador de stock (barra lateral) ──
            Container(
              width: 4,
              height: 52,
              decoration: BoxDecoration(
                color: _stockColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // ── Info principal ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre + badge de inactivo
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            color: product.isActive
                                ? AppColors.textPrimary
                                : AppColors.textDisabled,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            decoration: product.isActive
                                ? null
                                : TextDecoration.lineThrough,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!product.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Inactivo',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Categoría y código de barras
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _MiniChip(label: product.category, icon: Icons.category_outlined),
                      if (product.barcode != null && product.barcode!.isNotEmpty)
                        _MiniChip(label: product.barcode!, icon: Icons.qr_code_2_rounded),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // ── Precio y stock ──
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  currencyFmt.format(product.price),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.inventory_2_outlined,
                      size: 14,
                      color: _stockColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${product.stock} ${product.unit}',
                      style: TextStyle(
                        color: _stockColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textDisabled, size: 20),
          ],
        ),
      ),
    );
  }

  /// Color del indicador de stock según nivel
  Color get _stockColor {
    if (product.isOutOfStock) return AppColors.stockCritical;
    if (product.isLowStock) return AppColors.stockWarning;
    return AppColors.stockOk;
  }
}

// ── Mini Chip (categoría / barcode) ───────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _MiniChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textSecondary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State ───────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClearFilters;

  const _EmptyState({
    required this.hasFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            hasFilters ? Icons.search_off_rounded : Icons.inventory_2_outlined,
            size: 64,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: 16),
          Text(
            hasFilters
                ? 'No se encontraron productos con esos filtros'
                : 'No hay productos registrados',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          if (hasFilters)
            OutlinedButton.icon(
              onPressed: onClearFilters,
              icon: const Icon(Icons.clear_all_rounded),
              label: const Text('Limpiar filtros'),
            )
          else
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/products/new'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crear primer producto'),
            ),
        ],
      ),
    );
  }
}
