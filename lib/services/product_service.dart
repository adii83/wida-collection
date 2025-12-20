import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

import '../data/dummy_products.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

class ProductService extends GetxService {
  ProductService(this._supabaseService);

  final SupabaseService _supabaseService;

  final products = <Product>[].obs;
  final isLoading = false.obs;
  final RxnString lastError = RxnString();

  RealtimeChannel? _productsChannel;
  Timer? _productsRefreshDebounce;

  Future<void>? _inFlight;

  Future<ProductService> init() async {
    await fetchProducts();
    _subscribeProducts();
    return this;
  }

  void _subscribeProducts() {
    if (!_supabaseService.isReady) return;
    final client = _supabaseService.client;
    if (client == null) return;

    _productsChannel?.unsubscribe();
    _productsChannel = client.channel('public:products')
      ..onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'products',
        callback: (_) {
          _productsRefreshDebounce?.cancel();
          _productsRefreshDebounce = Timer(
            const Duration(milliseconds: 400),
            () => fetchProducts(forceRefresh: true),
          );
        },
      )
      ..subscribe();
  }

  Future<List<Product>> fetchProducts({bool forceRefresh = false}) async {
    if (_inFlight != null) {
      await _inFlight;
      return products;
    }
    if (products.isNotEmpty && !forceRefresh) {
      return products;
    }
    _inFlight = _loadFromApi();
    await _inFlight;
    _inFlight = null;
    return products;
  }

  Future<void> refresh() => fetchProducts(forceRefresh: true);

  Product? findById(String id) {
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadFromApi() async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = null;
    try {
      if (!_supabaseService.isReady) {
        // Supabase belum terkonfigurasi / belum siap (mis. mode demo/offline)
        products.assignAll(dummyProducts);
        return;
      }

      final query = _supabaseService.client!.from('products').select();

      dynamic data;
      try {
        // Prefer newest first if your table has `created_at`.
        data = await query.order('created_at', ascending: false);
      } on PostgrestException catch (e) {
        // If schema doesn't have created_at, retry without ordering.
        final msg = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
            .toLowerCase();
        final looksLikeMissingCreatedAt =
            msg.contains('created_at') &&
            (msg.contains('column') ||
                msg.contains('not found') ||
                msg.contains('schema cache') ||
                e.code == 'PGRST204');

        if (!looksLikeMissingCreatedAt) {
          rethrow;
        }
        data = await query;
      }

      final parsed = (data as List<dynamic>)
          .map(
            (row) => Product.fromJson(
              Map<String, dynamic>.from(row as Map<dynamic, dynamic>),
            ),
          )
          .where((p) => p.id.isNotEmpty)
          .toList();

      products.assignAll(parsed);
    } catch (e) {
      lastError.value = e.toString();
      // Jangan fallback ke dummy jika Supabase sudah ready.
      // Biar kelihatan jelas kalau ada problem RLS/schema/connection.
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    _productsRefreshDebounce?.cancel();
    _productsRefreshDebounce = null;
    _productsChannel?.unsubscribe();
    _productsChannel = null;
    super.onClose();
  }
}
