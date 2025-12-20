class Product {
  final String id;
  final String name;
  final String image; // can be asset path or URL
  final double price;
  final String description;

  /// Normalized category label used by the UI (e.g. Dresses, Jackets, Sweaters, Jeans, Pants, T-Shirts).
  ///
  /// If not provided by backend/API, it will be derived from [name]/[description].
  final String category;

  Product({
    required this.id,
    required this.name,
    required this.image,
    required this.price,
    this.description = '',
    this.category = '',
  });

  /// Category used by UI filters/counts.
  ///
  /// Some products in the app are constructed locally (e.g. dummy data) and may
  /// not provide [category]. In that case, we derive it from [name]/[description]
  /// using the same resolver as API/DB parsing.
  String get resolvedCategory {
    final c = category.trim();
    if (c.isNotEmpty) return c;
    return ProductCategories.resolve(
      name: name,
      description: description,
      rawCategory: '',
    );
  }

  // Factory to construct from API responses (e.g., dummyjson)
  factory Product.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['productId'] ?? '').toString();
    final name = (json['name'] ?? json['title'] ?? '').toString();
    final images = json['images'];
    String resolvedImage = (json['image'] ?? json['thumbnail'] ?? '')
        .toString();
    if (resolvedImage.isEmpty && images is List && images.isNotEmpty) {
      final first = images.first;
      if (first != null) {
        resolvedImage = first.toString();
      }
    }
    if (resolvedImage.isEmpty) {
      resolvedImage = 'assets/images/thrift1.jpg';
    }
    final priceRaw = json['price'];
    final price = priceRaw is num
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw?.toString() ?? '') ?? 0.0;

    final description = (json['description'] ?? '').toString();
    final rawCategory = (json['category'] ?? json['category_name'] ?? '')
        .toString();
    final resolvedCategory = ProductCategories.resolve(
      name: name,
      description: description,
      rawCategory: rawCategory,
    );
    return Product(
      id: id,
      name: name,
      image: resolvedImage,
      price: price,
      description: description,
      category: resolvedCategory,
    );
  }

  bool get isAssetImage => image.startsWith('assets/');
}

class ProductCategories {
  const ProductCategories._();

  static const dresses = 'Dresses';
  static const jackets = 'Jackets';
  static const sweaters = 'Sweaters';
  static const jeans = 'Jeans';
  static const pants = 'Pants';
  static const tshirts = 'T-Shirts';

  static const List<String> values = [
    dresses,
    jackets,
    sweaters,
    jeans,
    pants,
    tshirts,
  ];

  static String resolve({
    required String name,
    required String description,
    String? rawCategory,
  }) {
    final raw = (rawCategory ?? '').trim();
    if (raw.isNotEmpty) {
      final normalized = _normalizeRaw(raw);
      if (normalized != null) return normalized;
    }

    final text = '${name.toLowerCase()} ${description.toLowerCase()}';

    bool hasAny(List<String> keys) => keys.any(text.contains);

    if (hasAny(['dress', 'dresses', 'gown', 'gaun'])) return dresses;
    if (hasAny([
      'jacket',
      'jackets',
      'coat',
      'blazer',
      'windbreaker',
      'jaket',
    ])) {
      return jackets;
    }
    if (hasAny(['sweater', 'sweaters', 'hoodie', 'cardigan', 'sweatshirt'])) {
      return sweaters;
    }
    if (hasAny(['jeans', 'denim'])) return jeans;
    if (hasAny(['pants', 'trousers', 'chino', 'slacks', 'celana']))
      return pants;
    if (hasAny([
      't-shirt',
      'tshirt',
      'tee',
      'shirt',
      'polo',
      'kaos',
      'kemeja',
    ])) {
      return tshirts;
    }

    // If we can't confidently infer, default to a generic clothing category.
    return tshirts;
  }

  static String? _normalizeRaw(String raw) {
    final lower = raw.toLowerCase();

    // Already one of our categories
    for (final value in values) {
      if (lower == value.toLowerCase()) return value;
    }

    // Map common raw categories (e.g. FakeStore)
    // Note: FakeStore provides "men's clothing" / "women's clothing".
    if (lower.contains("men") && lower.contains('clothing')) return null;
    if (lower.contains("women") && lower.contains('clothing')) return null;

    // Fallback mappings
    if (lower.contains('dress')) return dresses;
    if (lower.contains('jacket') || lower.contains('coat')) return jackets;
    if (lower.contains('sweater') || lower.contains('hoodie')) return sweaters;
    if (lower.contains('jean') || lower.contains('denim')) return jeans;
    if (lower.contains('pant') || lower.contains('trouser')) return pants;
    if (lower.contains('shirt') ||
        lower.contains('t-shirt') ||
        lower.contains('tee')) {
      return tshirts;
    }

    return null;
  }
}
