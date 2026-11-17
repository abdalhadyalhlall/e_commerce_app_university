class StoreCategory {
  final int id;
  final String uuid;
  final String name;
  final String slug;

  const StoreCategory({
    required this.id,
    required this.uuid,
    required this.name,
    required this.slug,
  });
}

class StoreProduct {
  final int id;
  final String uuid;
  final String name;
  final String description;
  final double price;
  final String? image;
  final String? categoryName;

  const StoreProduct({
    required this.id,
    required this.uuid,
    required this.name,
    required this.description,
    required this.price,
    this.image,
    this.categoryName,
  });

  factory StoreProduct.fromJson(Map<String, dynamic> json) {
    final category = _asMap(json['category']);
    return StoreProduct(
      id: _asInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      price: _asDouble(json['price']),
      image: json['image']?.toString(),
      categoryName: category['name']?.toString(),
    );
  }
}

class CartItem {
  final String uuid;
  final int quantity;
  final StoreProduct product;
  final double subtotal;

  const CartItem({
    required this.uuid,
    required this.quantity,
    required this.product,
    required this.subtotal,
  });
}

class StoreOrderItem {
  final String uuid;
  final int quantity;
  final double price;
  final double subtotal;
  final StoreProduct product;

  const StoreOrderItem({
    required this.uuid,
    required this.quantity,
    required this.price,
    required this.subtotal,
    required this.product,
  });

  factory StoreOrderItem.fromJson(Map<String, dynamic> json) {
    return StoreOrderItem(
      uuid: json['uuid']?.toString() ?? json['id']?.toString() ?? '',
      quantity: _asInt(json['quantity']),
      price: _asDouble(json['price']),
      subtotal: _asDouble(json['subtotal'] ?? json['price']),
      product: StoreProduct.fromJson(_asMap(json['product'])),
    );
  }
}

class StoreOrder {
  final int id;
  final String uuid;
  final String status;
  final double totalPrice;
  final List<StoreOrderItem> items;
  final String createdAt;

  const StoreOrder({
    required this.id,
    required this.uuid,
    required this.status,
    required this.totalPrice,
    required this.items,
    required this.createdAt,
  });

  factory StoreOrder.fromJson(Map<String, dynamic> json) {
    final items = json['items'] is List ? json['items'] as List : const [];
    return StoreOrder(
      id: _asInt(json['id']),
      uuid: json['uuid']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalPrice: _asDouble(json['total_price']),
      items: items
          .whereType<Map>()
          .map(
            (item) => StoreOrderItem.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class StoreProductPage {
  final List<StoreProduct> products;
  final int currentPage;
  final int lastPage;

  const StoreProductPage({
    required this.products,
    required this.currentPage,
    required this.lastPage,
  });
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _asDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;
