import 'dart:async';

import 'package:clean_arch_session/core/networking/api_error_handler.dart';
import 'package:clean_arch_session/feature/store/data/order_realtime_service.dart';
import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/cart_usecases.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/catalog_usecases.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/order_usecases.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class StoreState {
  final List<StoreCategory> categories;
  final List<StoreProduct> products;
  final int catalogRevision;
  final int productPage;
  final int productLastPage;
  final List<CartItem> cartItems;
  final List<StoreOrder> orders;
  final String? selectedCategoryUuid;
  final bool loadingCategories;
  final bool loadingProducts;
  final bool loadingCart;
  final bool loadingOrders;
  final bool busy;
  final String? error;
  final String? message;

  const StoreState({
    this.categories = const [],
    this.products = const [],
    this.catalogRevision = 0,
    this.productPage = 1,
    this.productLastPage = 1,
    this.cartItems = const [],
    this.orders = const [],
    this.selectedCategoryUuid,
    this.loadingCategories = false,
    this.loadingProducts = false,
    this.loadingCart = false,
    this.loadingOrders = false,
    this.busy = false,
    this.error,
    this.message,
  });

  double get cartTotal =>
      cartItems.fold(0, (total, item) => total + item.subtotal);

  StoreState copyWith({
    List<StoreCategory>? categories,
    List<StoreProduct>? products,
    int? catalogRevision,
    int? productPage,
    int? productLastPage,
    List<CartItem>? cartItems,
    List<StoreOrder>? orders,
    String? selectedCategoryUuid,
    bool clearSelectedCategory = false,
    bool? loadingCategories,
    bool? loadingProducts,
    bool? loadingCart,
    bool? loadingOrders,
    bool? busy,
    String? error,
    String? message,
    bool clearFeedback = false,
  }) {
    return StoreState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      catalogRevision: catalogRevision ?? this.catalogRevision,
      productPage: productPage ?? this.productPage,
      productLastPage: productLastPage ?? this.productLastPage,
      cartItems: cartItems ?? this.cartItems,
      orders: orders ?? this.orders,
      selectedCategoryUuid: clearSelectedCategory
          ? null
          : selectedCategoryUuid ?? this.selectedCategoryUuid,
      loadingCategories: loadingCategories ?? this.loadingCategories,
      loadingProducts: loadingProducts ?? this.loadingProducts,
      loadingCart: loadingCart ?? this.loadingCart,
      loadingOrders: loadingOrders ?? this.loadingOrders,
      busy: busy ?? this.busy,
      error: clearFeedback ? null : error ?? this.error,
      message: clearFeedback ? null : message ?? this.message,
    );
  }
}

class StoreCubit extends Cubit<StoreState> {
  final CatalogUseCases _catalogUseCases;
  final CartUseCases _cartUseCases;
  final OrderUseCases _orderUseCases;
  final OrderRealtimeService _orderRealtimeService;
  late final StreamSubscription<OrderRealtimeEvent> _orderEventsSubscription;
  late final StreamSubscription<String> _orderErrorsSubscription;
  int _categoriesRequestId = 0;
  int _productsRequestId = 0;

  StoreCubit(
    this._catalogUseCases,
    this._cartUseCases,
    this._orderUseCases,
    this._orderRealtimeService,
  ) : super(const StoreState()) {
    _orderEventsSubscription = _orderRealtimeService.events.listen(
      _applyRealtimeOrder,
    );
    _orderErrorsSubscription = _orderRealtimeService.errors.listen(
      (error) => emit(state.copyWith(error: error)),
    );
    unawaited(_orderRealtimeService.connect());
  }

  Future<void> loadCategories() async {
    final requestId = ++_categoriesRequestId;
    emit(state.copyWith(loadingCategories: true, clearFeedback: true));
    try {
      final categories = await _catalogUseCases.getCategories();
      if (requestId != _categoriesRequestId) return;
      if (categories == null) {
        emit(state.copyWith(loadingCategories: false));
        return;
      }
      emit(state.copyWith(categories: categories, loadingCategories: false));
    } catch (error) {
      if (requestId != _categoriesRequestId) return;
      emit(
        state.copyWith(
          loadingCategories: false,
          error: ApiErrorHandler.getMessage(error),
        ),
      );
    }
  }

  Future<void> loadProducts({
    String? categoryUuid,
    int page = 1,
    bool append = false,
    bool refresh = false,
  }) async {
    final sameCategory = categoryUuid == state.selectedCategoryUuid;
    if (!append && sameCategory) {
      if (state.loadingProducts && !refresh) return;
      if (!refresh && state.products.isNotEmpty) return;
    }

    final keepCurrentProducts = refresh && sameCategory;
    final requestId = ++_productsRequestId;
    emit(
      state.copyWith(
        loadingProducts: true,
        selectedCategoryUuid: categoryUuid,
        clearSelectedCategory: categoryUuid == null,
        products: append || keepCurrentProducts ? state.products : const [],
        productPage: append || keepCurrentProducts ? state.productPage : 1,
        productLastPage: append || keepCurrentProducts
            ? state.productLastPage
            : 1,
        clearFeedback: true,
      ),
    );
    try {
      final result = await _catalogUseCases.getProducts(
        categoryUuid: categoryUuid,
        page: page,
      );
      if (requestId != _productsRequestId) return;
      if (result == null) {
        emit(state.copyWith(loadingProducts: false));
        return;
      }
      emit(
        state.copyWith(
          products: append
              ? [...state.products, ...result.products]
              : result.products,
          catalogRevision: state.catalogRevision + 1,
          productPage: result.currentPage,
          productLastPage: result.lastPage,
          loadingProducts: false,
        ),
      );
    } catch (error) {
      if (requestId != _productsRequestId) return;
      emit(
        state.copyWith(
          loadingProducts: false,
          error: ApiErrorHandler.getMessage(error),
        ),
      );
    }
  }

  Future<void> loadMoreProducts() {
    if (state.loadingProducts || state.productPage >= state.productLastPage) {
      return Future.value();
    }
    return loadProducts(
      categoryUuid: state.selectedCategoryUuid,
      page: state.productPage + 1,
      append: true,
    );
  }

  Future<void> loadCart() async {
    emit(state.copyWith(loadingCart: true, clearFeedback: true));
    try {
      final items = await _cartUseCases.getItems();
      emit(state.copyWith(cartItems: items, loadingCart: false));
    } catch (error) {
      emit(
        state.copyWith(
          loadingCart: false,
          error: ApiErrorHandler.getMessage(error),
        ),
      );
    }
  }

  Future<void> loadOrders() async {
    emit(state.copyWith(loadingOrders: true, clearFeedback: true));
    try {
      final orders = await _orderUseCases.getOrders();
      emit(state.copyWith(orders: orders, loadingOrders: false));
    } catch (error) {
      emit(
        state.copyWith(
          loadingOrders: false,
          error: ApiErrorHandler.getMessage(error),
        ),
      );
    }
  }

  Future<void> addToCart(StoreProduct product) async {
    await _runAction(() async {
      await _cartUseCases.add(product.uuid);
      final items = await _cartUseCases.getItems();
      emit(
        state.copyWith(cartItems: items, message: 'تمت إضافة المنتج إلى السلة'),
      );
    });
  }

  Future<void> updateCartItem(CartItem item, int quantity) async {
    if (quantity < 1) return;
    await _runAction(() async {
      await _cartUseCases.update(item.uuid, quantity);
      final items = await _cartUseCases.getItems();
      emit(state.copyWith(cartItems: items, message: 'تم تحديث الكمية'));
    });
  }

  Future<void> removeCartItem(CartItem item) async {
    await _runAction(() async {
      await _cartUseCases.remove(item.uuid);
      final items = await _cartUseCases.getItems();
      emit(state.copyWith(cartItems: items, message: 'تم حذف المنتج من السلة'));
    });
  }

  Future<void> clearCart() async {
    await _runAction(() async {
      await _cartUseCases.clear();
      emit(state.copyWith(cartItems: const [], message: 'تم إفراغ السلة'));
    });
  }

  Future<void> placeOrder() async {
    if (state.cartItems.isEmpty) return;
    await _runAction(() async {
      await _orderUseCases.place();
      final cartItems = await _cartUseCases.getItems();
      final orders = await _orderUseCases.getOrders();
      emit(
        state.copyWith(
          cartItems: cartItems,
          orders: orders,
          message: 'تم تأكيد الطلب بنجاح',
        ),
      );
    });
  }

  Future<StoreOrder?> loadOrderDetails(String uuid) async {
    try {
      return await _orderUseCases.getOrder(uuid);
    } catch (error) {
      emit(state.copyWith(error: ApiErrorHandler.getMessage(error)));
      return null;
    }
  }

  Future<void> deleteOrder(StoreOrder order) async {
    await _runAction(() async {
      await _orderUseCases.delete(order.uuid);
      final orders = await _orderUseCases.getOrders();
      emit(state.copyWith(orders: orders, message: 'تم حذف الطلب'));
    });
  }

  Future<void> clearFeedback() async {
    emit(state.copyWith(clearFeedback: true));
  }

  void _applyRealtimeOrder(OrderRealtimeEvent event) {
    final nextOrders = [...state.orders];
    final index = nextOrders.indexWhere(
      (order) =>
          (event.order.id != 0 && order.id == event.order.id) ||
          (event.order.uuid.isNotEmpty && order.uuid == event.order.uuid),
    );

    switch (event.action) {
      case 'created':
        if (index == -1) {
          nextOrders.insert(0, event.order);
        } else {
          nextOrders[index] = event.order;
        }
      case 'updated':
      case 'status_changed':
        if (index == -1) {
          nextOrders.insert(0, event.order);
        } else {
          nextOrders[index] = event.order;
        }
      case 'deleted':
        if (index != -1) nextOrders.removeAt(index);
      default:
        return;
    }

    emit(
      state.copyWith(
        orders: nextOrders,
        message: switch (event.action) {
          'created' => 'تمت إضافة طلب جديد',
          'updated' || 'status_changed' => 'تم تحديث حالة الطلب',
          'deleted' => 'تم حذف الطلب',
          _ => null,
        },
      ),
    );
  }

  @override
  Future<void> close() async {
    await _orderEventsSubscription.cancel();
    await _orderErrorsSubscription.cancel();
    await _orderRealtimeService.close();
    return super.close();
  }

  Future<void> _runAction(Future<void> Function() action) async {
    emit(state.copyWith(busy: true, clearFeedback: true));
    try {
      await action();
    } catch (error) {
      emit(state.copyWith(error: ApiErrorHandler.getMessage(error)));
    } finally {
      emit(state.copyWith(busy: false));
    }
  }
}
