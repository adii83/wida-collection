import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../models/admin_user.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';
import 'notification_service.dart';

class AdminService extends GetxService {
  AdminService(this._supabaseService, this._notificationService);

  final SupabaseService _supabaseService;
  final NotificationService _notificationService;

  bool get isReady => _supabaseService.isReady;

  // Admin Authentication
  Future<AdminUser?> adminLogin(String email, String password) async {
    try {
      if (!isReady) return null;

      await _supabaseService.signIn(email, password);

      final admin = await getCurrentAdmin();
      if (admin == null) {
        // Logged in, but not an admin based on profiles.role
        await _supabaseService.signOut();
        return null;
      }
      return admin;
    } catch (e) {
      debugPrint('Admin login error: $e');
      return null;
    }
  }

  Future<void> adminLogout() async {
    if (!isReady) return;
    await _supabaseService.signOut();
  }

  Future<AdminUser?> getCurrentAdmin() async {
    if (!isReady) return null;
    final userId = _supabaseService.currentUserId;
    if (userId == null) return null;

    try {
      final profile = await _supabaseService.fetchProfile(userId);
      final role = profile?.role;
      final isAdmin = role == 'admin' || role == 'super_admin';
      if (!isAdmin) return null;

      final email = _supabaseService.client?.auth.currentUser?.email;
      final name = (profile?.fullName.trim().isNotEmpty ?? false)
          ? profile!.fullName
          : (email ?? 'Admin');

      return AdminUser(
        id: userId,
        email: email ?? profile?.email ?? '',
        name: name,
        role: role ?? 'admin',
        createdAt: profile?.createdAt ?? DateTime.now(),
      );
    } catch (e) {
      debugPrint('Get current admin error: $e');
      return null;
    }
  }

  // Product Management
  Future<bool> addProduct(Product product) async {
    if (!isReady) return false;
    var imageValue = product.image;
    try {
      if (!kIsWeb && imageValue.isNotEmpty) {
        final file = File(imageValue);
        if (file.existsSync()) {
          final uploaded = await _supabaseService.uploadProductImage(
            file,
            productId: product.id,
          );
          if (uploaded == null || uploaded.isEmpty) {
            throw Exception('Upload gambar produk gagal');
          }
          imageValue = uploaded;
        }
      }

      await _supabaseService.client!.from('products').insert({
        'id': product.id,
        'name': product.name,
        'image': imageValue,
        'price': product.price,
        'category': product.category,
        'description': product.description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } on PostgrestException catch (e) {
      // If DB schema doesn't have `category`, retry without it.
      final msg = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
          .toLowerCase();
      final looksLikeMissingCategory =
          msg.contains('category') &&
          (msg.contains('column') ||
              msg.contains('not found') ||
              msg.contains('schema cache') ||
              e.code == 'PGRST204');
      if (!looksLikeMissingCategory) {
        debugPrint('Add product error: $e');
        return false;
      }
      try {
        await _supabaseService.client!.from('products').insert({
          'id': product.id,
          'name': product.name,
          'image': imageValue,
          'price': product.price,
          'description': product.description,
          'created_at': DateTime.now().toIso8601String(),
        });
        return true;
      } catch (e2) {
        debugPrint('Add product error: $e2');
        return false;
      }
    } catch (e) {
      debugPrint('Add product error: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    if (!isReady) return false;
    var imageValue = product.image;
    try {
      if (!kIsWeb && imageValue.isNotEmpty) {
        final file = File(imageValue);
        if (file.existsSync()) {
          final uploaded = await _supabaseService.uploadProductImage(
            file,
            productId: product.id,
          );
          if (uploaded == null || uploaded.isEmpty) {
            throw Exception('Upload gambar produk gagal');
          }
          imageValue = uploaded;
        }
      }

      await _supabaseService.client!
          .from('products')
          .update({
            'name': product.name,
            'image': imageValue,
            'price': product.price,
            'category': product.category,
            'description': product.description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id);
      return true;
    } on PostgrestException catch (e) {
      final msg = '${e.message} ${e.details ?? ''} ${e.hint ?? ''}'
          .toLowerCase();
      final looksLikeMissingCategory =
          msg.contains('category') &&
          (msg.contains('column') ||
              msg.contains('not found') ||
              msg.contains('schema cache') ||
              e.code == 'PGRST204');
      if (!looksLikeMissingCategory) {
        debugPrint('Update product error: $e');
        return false;
      }
      try {
        await _supabaseService.client!
            .from('products')
            .update({
              'name': product.name,
              'image': imageValue,
              'price': product.price,
              'description': product.description,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', product.id);
        return true;
      } catch (e2) {
        debugPrint('Update product error: $e2');
        return false;
      }
    } catch (e) {
      debugPrint('Update product error: $e');
      return false;
    }
  }

  Future<bool> deleteProduct(String productId) async {
    if (!isReady) return false;
    try {
      await _supabaseService.client!
          .from('products')
          .delete()
          .eq('id', productId);
      return true;
    } catch (e) {
      debugPrint('Delete product error: $e');
      return false;
    }
  }

  // Order Management
  Future<List<OrderModel>> fetchAllOrders() async {
    if (!isReady) return [];
    try {
      final data = await _supabaseService.client!
          .from('orders')
          .select()
          .order('created_at', ascending: false);
      return (data as List<dynamic>)
          .map((json) => OrderModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('Fetch orders error: $e');
      return [];
    }
  }

  Future<bool> updateOrderStatus(
    String orderId,
    String status, {
    String? trackingNumber,
    String? notes,
  }) async {
    if (!isReady) return false;
    try {
      final updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };
      if (trackingNumber != null) updates['tracking_number'] = trackingNumber;
      if (notes != null) updates['notes'] = notes;

      final updated = await _supabaseService.client!
          .from('orders')
          .update(updates)
          .eq('id', orderId)
          .select('id');

      if (updated is List && updated.isEmpty) return false;
      return true;
    } catch (e) {
      debugPrint('Update order status error: $e');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    if (!isReady) return false;
    try {
      final updated = await _supabaseService.client!
          .from('orders')
          .update({
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId)
          .select('id');

      if (updated is List && updated.isEmpty) return false;
      return true;
    } catch (e) {
      debugPrint('Update payment status error: $e');
      return false;
    }
  }

  // Refund Management
  Future<List<RefundModel>> fetchAllRefunds() async {
    if (!isReady) return [];
    try {
      final data = await _supabaseService.client!
          .from('refunds')
          .select()
          .order('requested_at', ascending: false);

      return (data as List<dynamic>)
          .map((json) => RefundModel.fromJson(Map<String, dynamic>.from(json)))
          .toList();
    } catch (e) {
      debugPrint('Fetch refunds error: $e');
      return [];
    }
  }

  Future<bool> processRefund(
    String refundId,
    String status,
    String adminId, {
    String? adminNotes,
  }) async {
    if (!isReady) return false;
    try {
      final client = _supabaseService.client!;

      final updated = await client
          .from('refunds')
          .update({
            'status': status,
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': adminId,
            if (adminNotes != null) 'admin_notes': adminNotes,
          })
          .eq('id', refundId)
          .select('id');

      if (updated is List && updated.isEmpty) return false;

      // If approved, update order payment status
      if (status == 'approved') {
        final refund = await client
            .from('refunds')
            .select('order_id')
            .eq('id', refundId)
            .single();
        await updatePaymentStatus(refund['order_id'].toString(), 'refunded');
      }

      return true;
    } catch (e) {
      debugPrint('Process refund error: $e');
      return false;
    }
  }

  // Notification Management
  Future<bool> sendCustomNotification({
    required String title,
    required String body,
    String? targetUserId,
    Map<String, dynamic>? data,
  }) async {
    if (!isReady) return false;
    try {
      List<String> parseTargetUserIds(String? raw) {
        if (raw == null) return const [];
        final cleaned = raw.trim();
        if (cleaned.isEmpty) return const [];

        // Accept comma / whitespace separated ids.
        final parts = cleaned
            .split(RegExp(r'[\s,]+'))
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();

        final uuidRegex = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        return parts.where((id) => uuidRegex.hasMatch(id)).toList();
      }

      final targetUserIds = parseTargetUserIds(targetUserId);

      // 1. Save to Database (History)
      if (targetUserIds.isEmpty) {
        // Broadcast
        await _supabaseService.client!.from('admin_notifications').insert({
          'title': title,
          'body': body,
          'target_user_id': null,
          'data': data,
          'created_at': DateTime.now().toIso8601String(),
        });
      } else {
        // One row per target user (target_user_id is UUID in DB)
        final rows = targetUserIds
            .map(
              (id) => {
                'title': title,
                'body': body,
                'target_user_id': id,
                'data': data,
                'created_at': DateTime.now().toIso8601String(),
              },
            )
            .toList();
        await _supabaseService.client!.from('admin_notifications').insert(rows);
      }

      // 2. Fetch Target Tokens
      List<String> tokens = [];
      if (targetUserIds.isNotEmpty) {
        // Specific Users
        final response = await _supabaseService.client!
            .from('profiles')
            .select('fcm_token')
            .inFilter('id', targetUserIds);

        tokens = (response as List)
            .map((e) => e['fcm_token'] as String?)
            .where((t) => t != null && t.isNotEmpty)
            .cast<String>()
            .toList();
      } else {
        // All Users (Broadcast)
        final response = await _supabaseService.client!
            .from('profiles')
            .select('fcm_token')
            .not('fcm_token', 'is', null); // Fetch all non-null tokens

        tokens = (response as List)
            .map((e) => e['fcm_token'] as String?)
            .where((t) => t != null && t.isNotEmpty)
            .cast<String>()
            .toList();
      }

      // Generate a consistent ID for this notification batch/event
      final notificationId = DateTime.now().millisecondsSinceEpoch.toString();

      // 3. Send via FCM V1
      if (tokens.isNotEmpty) {
        // Merge the ID into the data payload so the receiver uses this exact ID
        final finalData = {...?data, 'id': notificationId};

        await _notificationService.sendFCMV1Message(
          targetTokens: tokens,
          title: title,
          body: body,
          data: finalData,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Send notification error: $e');
      return false;
    }
  }

  // Statistics
  Future<Map<String, dynamic>> getAdminStatistics() async {
    if (!isReady) {
      return {
        'total_orders': 0,
        'pending_orders': 0,
        'total_revenue': 0.0,
        'pending_refunds': 0,
      };
    }

    try {
      final client = _supabaseService.client!;

      // Preferred: compute statistics on the server (single RPC), so results match
      // what Supabase sees and are not affected by max-rows limits.
      try {
        final rpc = await client.rpc('get_admin_statistics');
        Map<String, dynamic>? map;
        if (rpc is Map) {
          map = Map<String, dynamic>.from(rpc);
        } else if (rpc is List && rpc.isNotEmpty && rpc.first is Map) {
          map = Map<String, dynamic>.from(rpc.first as Map);
        }

        if (map != null && map.isNotEmpty) {
          final totalOrders = (map['total_orders'] as num?)?.toInt() ?? 0;
          final pendingOrders = (map['pending_orders'] as num?)?.toInt() ?? 0;
          final totalRevenue =
              (map['total_revenue'] as num?)?.toDouble() ?? 0.0;
          final pendingRefunds = (map['pending_refunds'] as num?)?.toInt() ?? 0;

          return {
            'total_orders': totalOrders,
            'pending_orders': pendingOrders,
            'total_revenue': totalRevenue,
            'pending_refunds': pendingRefunds,
          };
        }
      } on PostgrestException catch (_) {
        // If the RPC does not exist (or not allowed yet), fall back to client-side pagination.
      } catch (_) {
        // Any other rpc decoding issues: fall back.
      }

      // IMPORTANT:
      // PostgREST may enforce a max-rows limit. A plain `.select()` can be truncated
      // and cause dashboard numbers to be out-of-sync. We paginate to ensure counts
      // and sums reflect the real DB totals.

      const pageSize = 1000;
      const maxPages = 200; // safety guard (200k rows)

      int totalOrders = 0;
      int pendingOrders = 0;
      double totalRevenue = 0.0;

      for (int pageIndex = 0; pageIndex < maxPages; pageIndex++) {
        final from = pageIndex * pageSize;
        final to = from + pageSize - 1;
        final rows = await client
            .from('orders')
            .select('status, payment_status, total_amount')
            .range(from, to);

        final list = rows as List<dynamic>;
        if (list.isEmpty) break;

        totalOrders += list.length;

        for (final row in list) {
          final map = Map<String, dynamic>.from(row as Map);
          final status = (map['status'] as String? ?? '').toLowerCase();
          final paymentStatus = (map['payment_status'] as String? ?? '')
              .toLowerCase();

          if (status == 'pending') pendingOrders += 1;

          // Revenue counts only truly paid orders. Refund flow switches payment_status
          // to 'refunded', so refunded orders are excluded automatically.
          if (paymentStatus == 'paid') {
            final amount = map['total_amount'];
            if (amount is num) totalRevenue += amount.toDouble();
          }
        }

        if (list.length < pageSize) break;
      }

      int pendingRefunds = 0;
      for (int pageIndex = 0; pageIndex < maxPages; pageIndex++) {
        final from = pageIndex * pageSize;
        final to = from + pageSize - 1;
        final rows = await client
            .from('refunds')
            .select('status')
            .range(from, to);

        final list = rows as List<dynamic>;
        if (list.isEmpty) break;

        for (final row in list) {
          final map = Map<String, dynamic>.from(row as Map);
          final status = (map['status'] as String? ?? '').toLowerCase();
          if (status == 'pending') pendingRefunds += 1;
        }

        if (list.length < pageSize) break;
      }

      return {
        'total_orders': totalOrders,
        'pending_orders': pendingOrders,
        'total_revenue': totalRevenue,
        'pending_refunds': pendingRefunds,
      };
    } catch (e) {
      debugPrint('Get statistics error: $e');
      return {
        'total_orders': 0,
        'pending_orders': 0,
        'total_revenue': 0.0,
        'pending_refunds': 0,
      };
    }
  }
}
