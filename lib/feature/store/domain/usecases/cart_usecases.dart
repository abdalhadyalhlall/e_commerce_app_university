import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/domain/repositories/store_repository.dart';

class CartUseCases {
  final StoreRepository _repository;

  CartUseCases(this._repository);

  Future<List<CartItem>> getItems() => _repository.getCartItems();

  Future<void> add(String productUuid, {int quantity = 1}) {
    return _repository.addToCart(productUuid, quantity: quantity);
  }

  Future<void> update(String uuid, int quantity) {
    return _repository.updateCartItem(uuid, quantity);
  }

  Future<void> remove(String uuid) => _repository.removeCartItem(uuid);

  Future<void> clear() => _repository.clearCart();
}

