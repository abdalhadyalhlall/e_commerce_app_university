import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/domain/repositories/store_repository.dart';

class OrderUseCases {
  final StoreRepository _repository;

  OrderUseCases(this._repository);

  Future<void> place() => _repository.placeOrder();

  Future<List<StoreOrder>> getOrders() => _repository.getOrders();

  Future<StoreOrder> getOrder(String uuid) => _repository.getOrder(uuid);

  Future<void> delete(String uuid) => _repository.deleteOrder(uuid);
}
