import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
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
    try {
      var imageValue = product.image;
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
        'description': product.description,
        'created_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      debugPrint('Add product error: $e');
      return false;
    }
  }

  Future<bool> updateProduct(Product product) async {
    if (!isReady) return false;
    try {
      var imageValue = product.image;
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
            'description': product.description,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', product.id);
      return true;
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
      final updated = await _supabaseService.client!
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
        final refund = await _supabaseService.client!
            .from('refunds')
            .select()
            .eq('id', refundId)
            .single();

        await updatePaymentStatus(refund['order_id'], 'refunded');
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
      // 1. Save to Database (History)
      await _supabaseService.client!.from('admin_notifications').insert({
        'title': title,
        'body': body,
        'target_user_id': targetUserId,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Fetch Target Tokens
      List<String> tokens = [];
      if (targetUserId != null && targetUserId.isNotEmpty) {
        // Specific Users
        final userIds = targetUserId.split(',');
        final response = await _supabaseService.client!
            .from('profiles')
            .select('fcm_token')
            .inFilter('id', userIds);

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

      // 3. Send via FCM V1
      if (tokens.isNotEmpty) {
        await _notificationService.sendFCMV1Message(
          targetTokens: tokens,
          title: title,
          body: body,
          data: data,
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
      final orders = await fetchAllOrders();
      final refunds = await fetchAllRefunds();

      return {
        'total_orders': orders.length,
        'pending_orders': orders.where((o) => o.status == 'pending').length,
        'total_revenue': orders
            .where((o) => o.paymentStatus == 'paid')
            .fold(0.0, (sum, order) => sum + order.totalAmount),
        'pending_refunds': refunds.where((r) => r.status == 'pending').length,
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
