import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';

abstract interface class StoreRepository {
  Future<List<StoreCategory>?> getCategories();

  Future<StoreProductPage?> getProducts({
    String? categoryUuid,
    int page = 1,
  });

  Future<List<CartItem>> getCartItems();

  Future<void> addToCart(String productUuid, {int quantity = 1});

  Future<void> updateCartItem(String uuid, int quantity);

  Future<void> removeCartItem(String uuid);

  Future<void> clearCart();

  Future<void> placeOrder();

  Future<List<StoreOrder>> getOrders();

  Future<StoreOrder> getOrder(String uuid);

  Future<void> deleteOrder(String uuid);
}
