import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

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

  // Public products cache (FakeStore API)
  static const _publicApiBase = 'https://fakestoreapi.com';
  static const _publicCacheTtl = Duration(minutes: 10);
  // FakeStore API prices are in USD. Convert to IDR for display/checkout.
  // Adjust this rate if you want a different approximation.
  static const double _usdToIdrRate = 16000;
  DateTime? _publicCacheAt;
  List<Product> _publicCachedProducts = const [];

  /// Ensure a public (FakeStore) product exists in Supabase `products`.
  ///
  /// - Does NOT delete or modify admin-added products.
  /// - Only runs for products with ids prefixed by `fs_`.
  /// - Insert if missing, otherwise update mutable fields.
  Future<void> ensurePublicProductInSupabase(Product product) async {
    if (!_supabaseService.isReady) return;
    if (!product.id.startsWith('fs_')) return;

    final client = _supabaseService.client;
    if (client == null) return;

    try {
      final existing = await client
          .from('products')
          .select('id')
          .eq('id', product.id)
          .maybeSingle();

      final now = DateTime.now().toIso8601String();

      // Defensive: if a public product somehow still has USD price, convert to IDR
      // before persisting so DB and UI stay consistent.
      final priceToPersist = product.price < 1000
          ? (product.price * _usdToIdrRate)
          : product.price;

      final insertPayload = {
        'id': product.id,
        'name': product.name,
        'image': product.image,
        'price': priceToPersist,
        'description': product.description,
        'category': product.category,
        'created_at': now,
        'updated_at': now,
      };

      final updatePayload = {
        'name': product.name,
        'image': product.image,
        'price': priceToPersist,
        'description': product.description,
        'category': product.category,
        'updated_at': now,
      };

      if (existing == null) {
        try {
          await client.from('products').insert(insertPayload);
        } on PostgrestException catch (e) {
          final msg = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
              .toLowerCase();
          final looksLikeMissingCategory =
              msg.contains('category') &&
              (msg.contains('column') ||
                  msg.contains('not found') ||
                  msg.contains('schema cache') ||
                  e.code == 'PGRST204');
          if (!looksLikeMissingCategory) rethrow;
          final fallback = Map<String, dynamic>.from(insertPayload)
            ..remove('category');
          await client.from('products').insert(fallback);
        }
      } else {
        try {
          await client
              .from('products')
              .update(updatePayload)
              .eq('id', product.id);
        } on PostgrestException catch (e) {
          final msg = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
              .toLowerCase();
          final looksLikeMissingCategory =
              msg.contains('category') &&
              (msg.contains('column') ||
                  msg.contains('not found') ||
                  msg.contains('schema cache') ||
                  e.code == 'PGRST204');
          if (!looksLikeMissingCategory) rethrow;
          final fallback = Map<String, dynamic>.from(updatePayload)
            ..remove('category');
          await client.from('products').update(fallback).eq('id', product.id);
        }
      }
    } catch (_) {
      // Best-effort: failure here must not block cart/wishlist/checkout.
    }
  }

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
    _inFlight = _loadFromApi(forceRefresh: forceRefresh);
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

  Future<void> _loadFromApi({required bool forceRefresh}) async {
    if (isLoading.value) return;
    isLoading.value = true;
    lastError.value = null;
    try {
      // 1) Load Supabase products (admin/manual DB products) if available.
      final supabaseProducts = <Product>[];
      if (_supabaseService.isReady) {
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

        // If older runs persisted FakeStore products with USD values, correct them.
        // Also best-effort update back to Supabase to keep everything synchronized.
        for (final p in parsed) {
          if (p.id.startsWith('fs_') && p.price > 0 && p.price < 1000) {
            final fixed = Product(
              id: p.id,
              name: p.name,
              image: p.image,
              price: p.price * _usdToIdrRate,
              description: p.description,
              category: p.category,
            );
            supabaseProducts.add(fixed);
            unawaited(ensurePublicProductInSupabase(fixed));
          } else {
            supabaseProducts.add(p);
          }
        }
      }

      // 2) Load public clothing products (FakeStore API) and cache.
      final publicProducts = await _fetchPublicClothingProducts(
        forceRefresh: forceRefresh,
      );

      // 3) Merge (do NOT write/delete anything in Supabase).
      // Keep Supabase products first so admin-added products remain prominent.
      final merged = <Product>[];
      final seen = <String>{};
      void addAll(List<Product> list) {
        for (final p in list) {
          if (seen.add(p.id)) merged.add(p);
        }
      }

      if (supabaseProducts.isEmpty && !_supabaseService.isReady) {
        // Offline/demo mode: keep local dummy products.
        addAll(dummyProducts);
      }
      addAll(supabaseProducts);
      addAll(publicProducts);

      products.assignAll(merged);
    } catch (e) {
      lastError.value = e.toString();
      // Jangan fallback ke dummy jika Supabase sudah ready.
      // Biar kelihatan jelas kalau ada problem RLS/schema/connection.
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> _fetchPublicClothingProducts({
    required bool forceRefresh,
  }) async {
    final now = DateTime.now();
    final cacheFresh =
        _publicCacheAt != null &&
        now.difference(_publicCacheAt!) < _publicCacheTtl;
    if (!forceRefresh && cacheFresh) {
      return _publicCachedProducts;
    }

    try {
      // Only fetch clothing categories (exclude jewelery/electronics/accessories).
      final menUrl = Uri.parse(
        '$_publicApiBase/products/category/${Uri.encodeComponent("men's clothing")}',
      );
      final womenUrl = Uri.parse(
        '$_publicApiBase/products/category/${Uri.encodeComponent("women's clothing")}',
      );

      final responses = await Future.wait([
        http.get(menUrl).timeout(const Duration(seconds: 12)),
        http.get(womenUrl).timeout(const Duration(seconds: 12)),
      ]);

      final all = <dynamic>[];
      for (final r in responses) {
        if (r.statusCode >= 200 && r.statusCode < 300) {
          final decoded = jsonDecode(r.body);
          if (decoded is List) {
            all.addAll(decoded);
          }
        }
      }

      final parsed = all
          .whereType<Map<String, dynamic>>()
          .map((row) {
            // Prefix id to avoid collision with Supabase UUID/string ids.
            final rawId = (row['id'] ?? '').toString();
            final mapped = <String, dynamic>{...row};
            mapped['id'] = 'fs_$rawId';
            // Map to our Product model fields.
            mapped['name'] = row['title'];
            final price = row['price'];
            if (price is num) {
              mapped['price'] = price.toDouble() * _usdToIdrRate;
            } else {
              final parsed = double.tryParse(price?.toString() ?? '');
              if (parsed != null) {
                mapped['price'] = parsed * _usdToIdrRate;
              }
            }
            return Product.fromJson(mapped);
          })
          .where((p) => p.id.isNotEmpty)
          .toList();

      _publicCachedProducts = parsed;
      _publicCacheAt = now;
      return parsed;
    } catch (_) {
      // If fetch fails, keep last cached products (if any) without breaking UI.
      return _publicCachedProducts;
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
