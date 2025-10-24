class Product {
  final String id;
  final String name;
  final String image; // can be asset path or URL
  final double price;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
  });

  // Factory to construct from API responses (e.g., dummyjson)
  factory Product.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['productId'] ?? '').toString();
    final name = (json['name'] ?? json['title'] ?? '').toString();
    final image = (json['image'] ?? json['thumbnail'] ?? '').toString();
    final priceRaw = json['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '') ?? 0.0;
    return Product(id: id, name: name, image: image, price: price);
  }

  bool get isAssetImage => image.startsWith('assets/');
}
