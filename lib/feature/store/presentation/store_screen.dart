import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:clean_arch_session/feature/store/presentation/store_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const _ink = Color(0xFF172B4D);
const _brand = Color(0xFF176B5B);
const _canvas = Color(0xFFF5F7F6);

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  int _tabIndex = 0;
  Future<void>? _catalogRefreshInProgress;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = context.read<StoreCubit>();
      store.loadCategories();
      store.loadProducts();
      store.loadCart();
    });
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['اكتشف المنتجات', 'سلة التسوق', 'طلباتي'];
    return MultiBlocListener(
      listeners: [
        BlocListener<StoreCubit, StoreState>(
          listenWhen: (previous, current) =>
              previous.error != current.error ||
              previous.message != current.message,
          listener: (context, state) {
            final text = state.error ?? state.message;
            if (text == null) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(text, textDirection: TextDirection.rtl),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            context.read<StoreCubit>().clearFeedback();
          },
        ),
        BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state is AuthLoggedOut) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.login,
                (route) => false,
              );
              if (state.message.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      state.message,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                );
              }
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: _canvas,
        appBar: AppBar(
          backgroundColor: _canvas,
          title: Text(titles[_tabIndex], textDirection: TextDirection.rtl),
          actions: [
            IconButton(
              tooltip: 'تحديث',
              onPressed: _refreshCurrent,
              icon: const Icon(Icons.refresh_rounded),
            ),
            IconButton(
              tooltip: 'تسجيل الخروج',
              onPressed: () => context.read<AuthCubit>().logout(),
              icon: const Icon(Icons.logout_rounded),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: IndexedStack(
          index: _tabIndex,
          children: [
            _CatalogTab(onRefresh: _refreshCatalog),
            const _CartTab(),
            const _OrdersTab(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) {
            setState(() => _tabIndex = index);
            if (index == 0) {
              _refreshCatalog();
            } else if (index == 1) {
              context.read<StoreCubit>().loadCart();
            } else if (index == 2) {
              context.read<StoreCubit>().loadOrders();
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront_rounded),
              label: 'المتجر',
            ),
            NavigationDestination(
              icon: const _CartNavigationIcon(
                icon: Icons.shopping_bag_outlined,
              ),
              selectedIcon: const _CartNavigationIcon(
                icon: Icons.shopping_bag_rounded,
              ),
              label: 'السلة',
            ),
            const NavigationDestination(
              icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'طلباتي',
            ),
          ],
        ),
      ),
    );
  }

  void _refreshCurrent() {
    final store = context.read<StoreCubit>();
    if (_tabIndex == 1) {
      store.loadCart();
    } else if (_tabIndex == 2) {
      store.loadOrders();
    } else {
      _refreshCatalog();
    }
  }

  Future<void> _refreshCatalog() {
    final inProgress = _catalogRefreshInProgress;
    if (inProgress != null) return inProgress;

    final store = context.read<StoreCubit>();
    final refresh = _performCatalogRefresh(store);
    _catalogRefreshInProgress = refresh;
    return refresh.whenComplete(() {
      if (identical(_catalogRefreshInProgress, refresh)) {
        _catalogRefreshInProgress = null;
      }
    });
  }

  Future<void> _performCatalogRefresh(StoreCubit store) async {
    await Future.wait([
      store.loadCategories(),
      store.loadProducts(
        categoryUuid: store.state.selectedCategoryUuid,
        refresh: true,
      ),
    ]);
  }
}

class _CartNavigationIcon extends StatelessWidget {
  final IconData icon;

  const _CartNavigationIcon({required this.icon});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) => Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (state.cartItems.isNotEmpty)
            Positioned(
              top: -7,
              right: -9,
              child: Container(
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: const BoxDecoration(
                  color: Color(0xFFE85D4A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${state.cartItems.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogTab extends StatelessWidget {
  final Future<void> Function() onRefresh;

  const _CatalogTab({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: CustomScrollView(
            key: ValueKey(state.catalogRevision),
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _WelcomeBanner()),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 66,
                  child: state.loadingCategories && state.categories.isEmpty
                      ? const Center(
                          child: CircularProgressIndicator(color: _brand),
                        )
                      : ListView(
                          padding: const EdgeInsetsDirectional.fromSTEB(
                            16,
                            10,
                            16,
                            10,
                          ),
                          scrollDirection: Axis.horizontal,
                          children: [
                            _CategoryChip(
                              label: 'الكل',
                              selected: state.selectedCategoryUuid == null,
                              onTap: () =>
                                  context.read<StoreCubit>().loadProducts(),
                            ),
                            ...state.categories.map(
                              (category) => _CategoryChip(
                                label: category.name,
                                selected:
                                    category.uuid == state.selectedCategoryUuid,
                                onTap: () => context
                                    .read<StoreCubit>()
                                    .loadProducts(categoryUuid: category.uuid),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 20),
                sliver: state.loadingProducts && state.products.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(color: _brand),
                        ),
                      )
                    : state.products.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'لا توجد منتجات هنا',
                          subtitle: 'جرّب اختيار قسم آخر أو حدّث القائمة.',
                        ),
                      )
                    : SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            if (index == state.products.length) {
                              return _LoadMoreCard(
                                loading: state.loadingProducts,
                                onTap: context
                                    .read<StoreCubit>()
                                    .loadMoreProducts,
                              );
                            }
                            final product = state.products[index];
                            return _ProductCard(
                              product: product,
                              onTap: () =>
                                  _showProductDetails(context, product),
                            );
                          },
                          childCount:
                              state.products.length +
                              (state.productPage < state.productLastPage
                                  ? 1
                                  : 0),
                        ),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: 14,
                              crossAxisSpacing: 14,
                              childAspectRatio: 0.69,
                            ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProductDetails(BuildContext context, StoreProduct product) {
    final storeCubit = context.read<StoreCubit>();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: storeCubit,
        child: _ProductDetailsSheet(product: product),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.fromSTEB(16, 4, 16, 8),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF176B5B), Color(0xFF2E9279)],
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
        ),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'تسوّق براحة',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 7),
                Text(
                  'اكتشف مجموعتنا واختر ما يناسبك',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(19),
            ),
            child: const Icon(
              Icons.shopping_basket_rounded,
              color: Colors.white,
              size: 31,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: ChoiceChip(
        label: Text(label, textDirection: TextDirection.rtl),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: _brand,
        backgroundColor: Colors.white,
        side: BorderSide(color: selected ? _brand : const Color(0xFFE2E9E6)),
        labelStyle: TextStyle(
          color: selected ? Colors.white : _ink,
          fontWeight: FontWeight.w600,
        ),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final StoreProduct product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: _ProductImage(url: product.image),
                ),
              ),
              const SizedBox(height: 11),
              if (product.categoryName != null)
                Text(
                  product.categoryName!,
                  textDirection: TextDirection.rtl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _brand,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(height: 4),
              Text(
                product.name,
                textDirection: TextDirection.rtl,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _price(product.price),
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(
                        color: _brand,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE9F4F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: _brand,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadMoreCard extends StatelessWidget {
  final bool loading;
  final VoidCallback onTap;

  const _LoadMoreCard({required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: loading ? null : onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _brand,
        side: const BorderSide(color: Color(0xFFB8D7CD)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      child: loading
          ? const CircularProgressIndicator(color: _brand)
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.expand_more_rounded, size: 30),
                SizedBox(height: 7),
                Text('عرض المزيد'),
              ],
            ),
    );
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final StoreProduct product;

  const _ProductDetailsSheet({required this.product});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      decoration: const BoxDecoration(
        color: _canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 220,
                child: _ProductImage(url: product.image),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              product.name,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: _ink,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (product.categoryName != null) ...[
              const SizedBox(height: 6),
              Text(
                product.categoryName!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(
                  color: _brand,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              product.description.isEmpty
                  ? 'لا يتوفر وصف إضافي لهذا المنتج.'
                  : product.description,
              textDirection: TextDirection.rtl,
              style: const TextStyle(color: Color(0xFF61706B), height: 1.6),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _price(product.price),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: _brand,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _brand,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () {
                    context.read<StoreCubit>().addToCart(product);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.add_shopping_cart_rounded),
                  label: const Text('أضف إلى السلة'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  final String? url;

  const _ProductImage({this.url});

  @override
  Widget build(BuildContext context) {
    final parsed = url == null ? null : Uri.tryParse(url!);
    if (parsed == null || !parsed.hasAbsolutePath || parsed.host.isEmpty) {
      return const _ImagePlaceholder();
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const _ImagePlaceholder(),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFE9F1EE),
      child: const Center(
        child: Icon(Icons.inventory_2_outlined, color: _brand, size: 42),
      ),
    );
  }
}

class _CartTab extends StatelessWidget {
  const _CartTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        if (state.loadingCart && state.cartItems.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _brand));
        }
        if (state.cartItems.isEmpty) {
          return const _EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'سلتك فارغة',
            subtitle: 'ابدأ باكتشاف المنتجات وأضف ما يعجبك.',
          );
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: state.cartItems.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) =>
                    _CartItemCard(item: state.cartItems[index]),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 16,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'الإجمالي',
                            textDirection: TextDirection.rtl,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Text(
                          _price(state.cartTotal),
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            color: _brand,
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _brand,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: state.busy
                            ? null
                            : () => context.read<StoreCubit>().placeOrder(),
                        child: state.busy
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('تأكيد الطلب'),
                      ),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerEnd,
                      child: TextButton.icon(
                        onPressed: state.busy
                            ? null
                            : () => _confirmClearCart(context),
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 18,
                        ),
                        label: const Text('إفراغ السلة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmClearCart(BuildContext context) async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إفراغ السلة؟', textDirection: TextDirection.rtl),
        content: const Text(
          'سيتم حذف جميع المنتجات الموجودة في السلة.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إفراغ'),
          ),
        ],
      ),
    );
    if (shouldClear == true && context.mounted) {
      await context.read<StoreCubit>().clearCart();
    }
  }
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final store = context.read<StoreCubit>();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: SizedBox(
              width: 76,
              height: 76,
              child: _ProductImage(url: item.product.image),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _price(item.subtotal),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                    color: _brand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuantityButton(
                      icon: Icons.remove,
                      onTap: item.quantity > 1
                          ? () => store.updateCartItem(item, item.quantity - 1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('${item.quantity}'),
                    ),
                    _QuantityButton(
                      icon: Icons.add,
                      onTap: () =>
                          store.updateCartItem(item, item.quantity + 1),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'حذف',
            onPressed: () => store.removeCartItem(item),
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _QuantityButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 27,
        height: 27,
        decoration: BoxDecoration(
          color: const Color(0xFFE9F4F0),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: _brand),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  const _OrdersTab();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<StoreCubit, StoreState>(
      builder: (context, state) {
        if (state.loadingOrders && state.orders.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _brand));
        }
        if (state.orders.isEmpty) {
          return const _EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'لا توجد طلبات بعد',
            subtitle: 'ستظهر طلباتك هنا بعد إتمام الشراء.',
          );
        }
        return RefreshIndicator(
          onRefresh: context.read<StoreCubit>().loadOrders,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.orders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) => _OrderCard(
              order: state.orders[index],
              onTap: () => _showOrderDetails(context, state.orders[index]),
              onDelete: () => _confirmDeleteOrder(context, state.orders[index]),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showOrderDetails(BuildContext context, StoreOrder order) async {
    final details = await context.read<StoreCubit>().loadOrderDetails(
      order.uuid,
    );
    if (!context.mounted || details == null) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تفاصيل الطلب', textDirection: TextDirection.rtl),
        content: SizedBox(
          width: 360,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('رقم الطلب: ${details.uuid}'),
                const SizedBox(height: 8),
                Text('الحالة: ${_statusLabel(details.status)}'),
                const Divider(height: 24),
                ...details.items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.product.name} × ${item.quantity}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(_price(item.subtotal)),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 24),
                Text(
                  'الإجمالي: ${_price(details.totalPrice)}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteOrder(
    BuildContext context,
    StoreOrder order,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الطلب؟', textDirection: TextDirection.rtl),
        content: const Text(
          'لا يمكن التراجع عن حذف الطلب.',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (shouldDelete == true && context.mounted) {
      await context.read<StoreCubit>().deleteOrder(order);
    }
  }
}

class _OrderCard extends StatelessWidget {
  final StoreOrder order;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _OrderCard({
    required this.order,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F4F0),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.receipt_long_rounded, color: _brand),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'طلب #${order.uuid.substring(0, order.uuid.length > 8 ? 8 : order.uuid.length)}',
                      style: const TextStyle(
                        color: _ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${_statusLabel(order.status)} · ${order.items.length} منتجات',
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        color: Color(0xFF718079),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _price(order.totalPrice),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: _brand,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: 'حذف الطلب',
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: const Color(0xFFE9F4F0),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Icon(icon, color: _brand, size: 38),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF718079), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

String _price(double value) => value.toStringAsFixed(2);

String _statusLabel(String status) {
  switch (status.toLowerCase()) {
    case 'pending':
      return 'قيد الانتظار';
    case 'completed':
      return 'مكتمل';
    case 'cancelled':
      return 'ملغي';
    case 'processing':
      return 'قيد التجهيز';
    default:
      return status;
  }
}
