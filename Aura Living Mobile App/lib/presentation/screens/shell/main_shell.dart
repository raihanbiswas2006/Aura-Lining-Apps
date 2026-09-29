import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../domain/entities/category.dart';
import '../../../domain/entities/product.dart';
import '../../blocs/cart/cart_cubit.dart';
import '../../blocs/catalog/catalog_cubit.dart';
import '../../blocs/wishlist/wishlist_cubit.dart';
import '../account/profile_screen.dart';
import '../cart/cart_screen.dart';
import '../checkout/checkout_screen.dart';
import '../home/home_screen.dart';
import '../product/product_detail_screen.dart';
import '../search/search_modal.dart';
import '../shop/category_directory_screen.dart';
import '../shop/product_listing_screen.dart';
import '../wishlist/wishlist_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _navigateToProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          onBack: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  void _navigateToCategory(Category category) {
    context.read<CatalogCubit>().selectCategory(category.slug);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListingScreen(
          categoryId: category.slug,
          categoryTitle: category.title,
          onProductSelected: _navigateToProduct,
        ),
      ),
    );
  }

  void _navigateToCollection(String tag, String title) {
    context.read<CatalogCubit>().loadCatalog(tag: tag);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListingScreen(
          initialTag: tag,
          categoryTitle: title,
          onProductSelected: _navigateToProduct,
        ),
      ),
    );
  }

  void _openSearch() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchModal(
        onSearchSubmitted: (query) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProductListingScreen(
                initialSearchQuery: query,
                categoryTitle: 'Search: "$query"',
                onProductSelected: _navigateToProduct,
              ),
            ),
          );
        },
        onProductSelected: _navigateToProduct,
      ),
    );
  }

  void _openCheckout() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          onOrderComplete: () {
            setState(() {
              _currentIndex = 0; // Return to Home
            });
          },
          onViewOrders: () {
            setState(() {
              _currentIndex = 4; // Switch to Account
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tab 0: Home
          HomeScreen(
            onProductSelected: _navigateToProduct,
            onCategorySelected: _navigateToCategory,
            onOpenSearch: _openSearch,
            onOpenCart: () => _onTabTapped(3),
            onOpenWishlist: () => _onTabTapped(2),
            onCollectionSelected: _navigateToCollection,
          ),

          // Tab 1: Shop / Categories
          CategoryDirectoryScreen(
            onCategorySelected: _navigateToCategory,
          ),

          // Tab 2: Wishlist
          WishlistScreen(
            onProductSelected: _navigateToProduct,
            onExplore: () => _onTabTapped(0),
          ),

          // Tab 3: Cart
          CartScreen(
            onProceedToCheckout: _openCheckout,
            onExplore: () => _onTabTapped(0),
          ),

          // Tab 4: Account
          ProfileScreen(
            onNavigateToWishlist: () => _onTabTapped(2),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.border, width: 1.0),
          ),
        ),
        child: BlocBuilder<CartCubit, CartState>(
          builder: (context, cartState) {
            final cartCount = cartState.totalItemCount;

            return BlocBuilder<WishlistCubit, WishlistState>(
              builder: (context, wishlistState) {
                final wishlistCount = wishlistState.productIds.length;

                return BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: _onTabTapped,
                  type: BottomNavigationBarType.fixed,
                  selectedItemColor: AppColors.primary,
                  unselectedItemColor: AppColors.textMuted,
                  selectedLabelStyle: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                  unselectedLabelStyle: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                  items: [
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.home_outlined),
                      activeIcon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.grid_view_outlined),
                      activeIcon: Icon(Icons.grid_view_sharp),
                      label: 'Shop',
                    ),
                    BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.favorite_border),
                          if (wishlistCount > 0)
                            Positioned(
                              top: -3,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.discountBadge,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$wishlistCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      activeIcon: const Icon(Icons.favorite),
                      label: 'Wishlist',
                    ),
                    BottomNavigationBarItem(
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_bag_outlined),
                          if (cartCount > 0)
                            Positioned(
                              top: -3,
                              right: -4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 14,
                                  minHeight: 14,
                                ),
                                child: Text(
                                  '$cartCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      activeIcon: const Icon(Icons.shopping_bag),
                      label: 'Bag',
                    ),
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.person_outline),
                      activeIcon: Icon(Icons.person),
                      label: 'Account',
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
