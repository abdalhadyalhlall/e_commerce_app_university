import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/domain/repositories/store_repository.dart';

class CatalogUseCases {
  final StoreRepository _repository;

  CatalogUseCases(this._repository);

  Future<List<StoreCategory>?> getCategories() {
    return _repository.getCategories();
  }

  Future<StoreProductPage?> getProducts({
    String? categoryUuid,
    int page = 1,
  }) {
    return _repository.getProducts(
      categoryUuid: categoryUuid,
      page: page,
    );
  }
}
