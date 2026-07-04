// ============================================================
// lib/features/products/data/datasources/product_remote_datasource.dart
// Datasource remoto — Supabase queries para la tabla products
// ============================================================

import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/product.dart';
import '../../../../core/constants/app_constants.dart';

/// Acceso directo a la tabla `products` en Supabase.
/// Toda la lógica de serialización/deserialización vive aquí.
class ProductRemoteDatasource {
  final SupabaseClient _client;
  const ProductRemoteDatasource(this._client);

  // ── Deserialización ─────────────────────────────────────────

  /// Convierte un mapa JSON de Supabase a la entidad [Product].
  Product _fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        barcode: json['barcode'] as String?,
        name: json['name'] as String,
        description: json['description'] as String?,
        category: (json['category'] as String?) ?? 'General',
        price: (json['price'] as num).toDouble(),
        costPrice: (json['cost_price'] as num).toDouble(),
        stock: (json['stock'] as num).toInt(),
        minStock: (json['min_stock'] as num).toInt(),
        unit: (json['unit'] as String?) ?? 'unidad',
        isActive: json['is_active'] as bool? ?? true,
        imageUrl: json['image_url'] as String?,
        supplier: json['supplier'] as String?,
        createdBy: json['created_by'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  // ── US-014: Listar productos ───────────────────────────────

  /// Obtiene productos con paginación, búsqueda y filtro de categoría.
  ///
  /// La búsqueda con [query] filtra por nombre (ilike) o código de barras exacto.
  /// Los filtros se aplican ANTES de order() y range() para mantener
  /// el tipo PostgrestFilterBuilder correcto.
  Future<List<Product>> getProducts({
    String? query,
    String? category,
    bool activeOnly = true,
    int page = 0,
    int pageSize = 20,
  }) async {
    var q = _client.from(AppConstants.tableProducts).select();

    // Filtro de estado
    if (activeOnly) {
      q = q.eq('is_active', true);
    }

    // Filtro de categoría
    if (category != null && category.isNotEmpty) {
      q = q.eq('category', category);
    }

    // Búsqueda por nombre o código de barras
    if (query != null && query.trim().isNotEmpty) {
      final term = query.trim();
      // Buscar por código de barras exacto O nombre parcial (ilike)
      q = q.or('barcode.eq.$term,name.ilike.%$term%');
    }

    // Ordenar y paginar DESPUÉS de aplicar filtros
    final results = await q
        .order('name', ascending: true)
        .range(page * pageSize, (page + 1) * pageSize - 1);

    return results.map<Product>(_fromJson).toList();
  }

  // ── US-014: Obtener por ID ─────────────────────────────────

  /// Obtiene un producto por su UUID.
  Future<Product> getProductById(String productId) async {
    final result = await _client
        .from(AppConstants.tableProducts)
        .select()
        .eq('id', productId)
        .single();

    return _fromJson(result);
  }

  // ── US-014: Buscar por código de barras ────────────────────

  /// Busca un producto por su código de barras.
  /// Retorna null si no se encuentra (no es un error).
  Future<Product?> getProductByBarcode(String barcode) async {
    final result = await _client
        .from(AppConstants.tableProducts)
        .select()
        .eq('barcode', barcode)
        .maybeSingle();

    if (result == null) return null;
    return _fromJson(result);
  }

  // ── US-013: Crear producto ─────────────────────────────────

  /// Inserta un nuevo producto en la tabla `products`.
  Future<Product> createProduct({
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
    final userId = _client.auth.currentUser?.id;

    final payload = <String, dynamic>{
      'name': name,
      'category': category,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'min_stock': minStock,
      'unit': unit,
      'is_active': true,
      ?'barcode': barcode,
      ?'description': description,
      ?'image_url': imageUrl,
      ?'supplier': supplier,
      ?'created_by': userId,
    };

    final result = await _client
        .from(AppConstants.tableProducts)
        .insert(payload)
        .select()
        .single();

    return _fromJson(result);
  }

  // ── US-015: Actualizar producto ────────────────────────────

  /// Actualiza campos específicos de un producto existente.
  /// Solo envía los campos que no son null para minimizar la query.
  Future<Product> updateProduct({
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
    final payload = <String, dynamic>{
      ?'barcode': barcode,
      ?'name': name,
      ?'description': description,
      ?'category': category,
      ?'price': price,
      ?'cost_price': costPrice,
      ?'stock': stock,
      ?'min_stock': minStock,
      ?'unit': unit,
      ?'is_active': isActive,
      ?'image_url': imageUrl,
      ?'supplier': supplier,
    };

    final result = await _client
        .from(AppConstants.tableProducts)
        .update(payload)
        .eq('id', productId)
        .select()
        .single();

    return _fromJson(result);
  }
}
