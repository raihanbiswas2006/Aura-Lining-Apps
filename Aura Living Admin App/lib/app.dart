import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'core/presentation/admin_app_shell.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/dashboard/presentation/dashboard_screen.dart';
import 'features/products/presentation/product_list_screen.dart';
import 'features/products/presentation/product_detail_screen.dart';
import 'features/products/presentation/add_edit_product_screen.dart';
import 'features/products/presentation/category_management_screen.dart';
import 'features/orders/presentation/order_list_screen.dart';
import 'features/orders/presentation/order_detail_screen.dart';
import 'features/reviews/presentation/moderation_promos_tab_screen.dart';
import 'features/promotions/presentation/add_edit_coupon_screen.dart';
import 'features/settings/presentation/more_settings_screen.dart';
import 'features/customers/presentation/customer_directory_screen.dart';
import 'features/customers/presentation/customer_detail_screen.dart';
import 'features/settings/presentation/store_settings_screen.dart';
import 'features/settings/presentation/staff_management_screen.dart';
import 'features/settings/presentation/admin_profile_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<AuthState>(ref.watch(authControllerProvider));
  ref.listen<AuthState>(authControllerProvider, (_, next) {
    authNotifier.value = next;
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authControllerProvider);
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      // Authentication
      GoRoute(
        path: '/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),

      // 5-Tab App Shell
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AdminAppShell(child: child);
        },
        routes: [
          // Tab 1: Dashboard
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),

          // Tab 2: Products & Inventory
          GoRoute(
            path: '/products',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ProductListScreen(),
            ),
          ),

          // Tab 3: Orders
          GoRoute(
            path: '/orders',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: OrderListScreen(),
            ),
          ),

          // Tab 4: Moderation & Promos
          GoRoute(
            path: '/moderation',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ModerationPromosTabScreen(),
            ),
          ),

          // Tab 5: Settings & Operations
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MoreSettingsScreen(),
            ),
          ),
        ],
      ),

      // Sub-routes pushed on top of root navigator (full screen experience)
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/add',
        builder: (context, state) => const AddEditProductScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditProductScreen(productId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ProductDetailScreen(productId: id);
        },
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/products/categories',
        builder: (context, state) => const CategoryManagementScreen(),
      ),

      // Orders Detail Sub-route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/orders/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return OrderDetailScreen(orderId: id);
        },
      ),

      // Coupons Sub-routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/moderation/coupons/add',
        builder: (context, state) => const AddEditCouponScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/moderation/coupons/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddEditCouponScreen(couponId: id);
        },
      ),

      // Customers Sub-routes
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/customers',
        builder: (context, state) => const CustomerDirectoryScreen(),
      ),
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/customers/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CustomerDetailScreen(customerId: id);
        },
      ),

      // Store Settings Sub-route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/store',
        builder: (context, state) => const StoreSettingsScreen(),
      ),

      // Staff Management Sub-route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/staff',
        builder: (context, state) => const StaffManagementScreen(),
      ),

      // Admin Profile Sub-route
      GoRoute(
        parentNavigatorKey: _rootNavigatorKey,
        path: '/settings/profile',
        builder: (context, state) => const AdminProfileScreen(),
      ),
    ],
  );
});

class AuraLivingAdminApp extends ConsumerWidget {
  const AuraLivingAdminApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Aura Living Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
