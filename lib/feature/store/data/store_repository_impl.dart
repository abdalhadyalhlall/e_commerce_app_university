import 'package:clean_arch_session/core/networking/api_constants.dart';
import 'package:clean_arch_session/core/networking/api_service.dart';
import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/domain/repositories/store_repository.dart';

class StoreRepositoryImpl implements StoreRepository {
  final ApiService _api;

  StoreRepositoryImpl(this._api);

  @override
  Future<List<StoreCategory>?> getCategories() async {
    final response = await _api.get(ApiConstants.categories);
    if (response.statusCode == 304) return null;

    final data = _asMap(response.data)['data'];
    return _asMapList(data)
        .map(
          (json) => StoreCategory(
            id: _asInt(json['id']),
            uuid: json['uuid']?.toString() ?? '',
            name: json['name']?.toString() ?? '',
            slug: json['slug']?.toString() ?? '',
          ),
        )
        .toList();
  }

  @override
  Future<StoreProductPage?> getProducts({
    String? categoryUuid,
    int page = 1,
  }) async {
    final response = await _api.get(
      ApiConstants.products,
      queryParameters: {
        'category_uuid': ?categoryUuid,
        if (page > 1) 'page': page,
      },
    );
    if (response.statusCode == 304) return null;

    final json = _asMap(response.data);
    final meta = _asMap(json['meta']);
    return StoreProductPage(
      products: _asMapList(json['data']).map(_productFromJson).toList(),
      currentPage: _asInt(meta['current_page']).clamp(1, 1 << 31).toInt(),
      lastPage: _asInt(meta['last_page']).clamp(1, 1 << 31).toInt(),
    );
  }

  @override
  Future<List<CartItem>> getCartItems() async {
    final response = await _api.get(ApiConstants.cart);
    final data = _asMap(_asMap(response.data)['data']);
    return _asMapList(data['items'])
        .map(
          (json) => CartItem(
            uuid: json['uuid']?.toString() ?? '',
            quantity: _asInt(json['quantity']),
            product: _productFromJson(_asMap(json['product'])),
            subtotal: _asDouble(json['subtotal']),
          ),
        )
        .toList();
  }

  @override
  Future<void> addToCart(String productUuid, {int quantity = 1}) async {
    await _api.post(
      ApiConstants.cart,
      queryParameters: {'product_uuid': productUuid, 'quantity': quantity},
    );
    _api.invalidateCache(ApiConstants.cart);
  }

  @override
  Future<void> updateCartItem(String uuid, int quantity) async {
    await _api.put(
      '${ApiConstants.cart}/$uuid',
      queryParameters: {'quantity': quantity},
    );
    _api.invalidateCache(ApiConstants.cart);
  }

  @override
  Future<void> removeCartItem(String uuid) async {
    await _api.delete('${ApiConstants.cart}/$uuid');
    _api.invalidateCache(ApiConstants.cart);
  }

  @override
  Future<void> clearCart() async {
    await _api.delete('${ApiConstants.cart}/clear');
    _api.invalidateCache(ApiConstants.cart);
  }

  @override
  Future<void> placeOrder() async {
    await _api.post(ApiConstants.orders);
    _api.invalidateCache(ApiConstants.cart);
    _api.invalidateCache(ApiConstants.orders);
  }

  @override
  Future<List<StoreOrder>> getOrders() async {
    final response = await _api.get(ApiConstants.orders);
    final data = _asMap(_asMap(response.data)['data']);
    return _asMapList(data['orders']).map(_orderFromJson).toList();
  }

  @override
  Future<StoreOrder> getOrder(String uuid) async {
    final response = await _api.get('${ApiConstants.orders}/$uuid');
    return _orderFromJson(_asMap(_asMap(response.data)['data']));
  }

  @override
  Future<void> deleteOrder(String uuid) async {
    await _api.delete('${ApiConstants.orders}/$uuid');
    _api.invalidateCache(ApiConstants.orders);
  }

  StoreProduct _productFromJson(Map<String, dynamic> json) {
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

  StoreOrder _orderFromJson(Map<String, dynamic> json) => StoreOrder(
    id: _asInt(json['id']),
    uuid: json['uuid']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    totalPrice: _asDouble(json['total_price']),
    items: _asMapList(json['items']).map(StoreOrderItem.fromJson).toList(),
    createdAt: json['created_at']?.toString() ?? '',
  );
}

int _asInt(dynamic value) => int.tryParse(value?.toString() ?? '') ?? 0;

double _asDouble(dynamic value) =>
    double.tryParse(value?.toString() ?? '') ?? 0;

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
