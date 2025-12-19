import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/admin_user.dart';
import '../models/order_model.dart';
import '../models/refund_model.dart';
import '../models/product_model.dart';
import 'supabase_service.dart';

class AdminService extends GetxService {
  AdminService(this._supabaseService);

  final SupabaseService _supabaseService;

  // Hardcoded admin credentials for demo (in production, use proper auth)
  static const Map<String, String> _adminCredentials = {
    'admin@widacollection.com': 'admin123',
    'superadmin@widacollection.com': 'superadmin123',
  };

  bool get isReady => _supabaseService.isReady;

  // Admin Authentication
  Future<AdminUser?> adminLogin(String email, String password) async {
    try {
      // Simple credential check (for demo purposes)
      if (_adminCredentials[email] == password) {
        final role = email.contains('superadmin') ? 'super_admin' : 'admin';

        // In production, verify with Supabase admin table
        return AdminUser(
          id: 'admin_${email.split('@')[0]}',
          email: email,
          name: role == 'super_admin' ? 'Super Admin' : 'Admin',
          role: role,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      debugPrint('Admin login error: $e');
      return null;
    }
  }

  // Product Management
  Future<bool> addProduct(Product product) async {
    if (!isReady) return false;
    try {
      await _supabaseService.client!.from('products').insert({
        'id': product.id,
        'name': product.name,
        'image': product.image,
        'price': product.price,
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
      await _supabaseService.client!
          .from('products')
          .update({
            'name': product.name,
            'image': product.image,
            'price': product.price,
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

      await _supabaseService.client!
          .from('orders')
          .update(updates)
          .eq('id', orderId);
      return true;
    } catch (e) {
      debugPrint('Update order status error: $e');
      return false;
    }
  }

  Future<bool> updatePaymentStatus(String orderId, String paymentStatus) async {
    if (!isReady) return false;
    try {
      await _supabaseService.client!
          .from('orders')
          .update({
            'payment_status': paymentStatus,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', orderId);
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
      await _supabaseService.client!
          .from('refunds')
          .update({
            'status': status,
            'processed_at': DateTime.now().toIso8601String(),
            'processed_by': adminId,
            if (adminNotes != null) 'admin_notes': adminNotes,
          })
          .eq('id', refundId);

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
      await _supabaseService.client!.from('admin_notifications').insert({
        'title': title,
        'body': body,
        'target_user_id': targetUserId,
        'data': data,
        'created_at': DateTime.now().toIso8601String(),
      });
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
