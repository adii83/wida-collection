import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/order_model.dart';
import '../models/cart_item.dart';

class MidtransService {
  static const String _sandboxUrl =
      'https://app.sandbox.midtrans.com/snap/v1/transactions';
  static const String _productionUrl =
      'https://app.midtrans.com/snap/v1/transactions'; // For future use

  // Use Sandbox for now
  String get _baseUrl => _sandboxUrl;

  String get _serverKey => dotenv.env['MIDTRANS_SERVER_KEY'] ?? '';

  Future<String?> createSnapTransaction({
    required OrderModel order,
    required List<CartItem> items,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    if (_serverKey.isEmpty) {
      throw Exception('Midtrans Server Key not configured in .env');
    }

    final url = Uri.parse(_baseUrl);
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': 'Basic ${base64Encode(utf8.encode('$_serverKey:'))}',
    };

    final body = {
      'transaction_details': {
        'order_id': order.id,
        'gross_amount': order.totalAmount.toInt(),
      },
      'credit_card': {'secure': true},
      'item_details': items.map((item) {
        return {
          'id': item.product.id,
          'price': item.product.price.toInt(),
          'quantity': item.quantity,
          'name': item.product.name.length > 50
              ? item.product.name.substring(0, 50)
              : item.product.name,
        };
      }).toList(),
      'customer_details': {
        'first_name': customerName,
        'email': customerEmail,
        'phone': customerPhone,
        'billing_address': {
          'first_name': customerName,
          'address': order.shippingAddress,
          'country_code': 'IDN',
        },
        'shipping_address': {
          'first_name': customerName,
          'address': order.shippingAddress,
          'phone': customerPhone,
          'country_code': 'IDN',
        },
      },
      'enabled_payments': ['qris', 'gopay', 'shopeepay', 'other_qris'],
      // To force Qris or specific flow:
      // 'callbacks': { ... }
    };

    try {
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['redirect_url']; // This is the URL we need to launch
      } else {
        throw Exception(
          'Failed to create Midtrans transaction: ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Midtrans Error: $e');
    }
  }
}
