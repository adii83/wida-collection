import 'product_model.dart';

class CartItem {
  CartItem({required this.product, this.quantity = 1, this.id});

  final String? id; // Optional: Links back to the CartItemModel id if from cart
  final Product product;
  int quantity;

  double get total => product.price * quantity;
}
