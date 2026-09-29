import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/di/injection.dart';
import '../data/datasources/local_storage_service.dart';
import '../domain/repositories/i_auth_repository.dart';
import '../domain/repositories/i_cart_repository.dart';
import '../domain/repositories/i_order_repository.dart';
import '../domain/repositories/i_product_repository.dart';
import '../presentation/blocs/auth/auth_cubit.dart';
import '../presentation/blocs/cart/cart_cubit.dart';
import '../presentation/blocs/catalog/catalog_cubit.dart';
import '../presentation/blocs/checkout/checkout_cubit.dart';
import '../presentation/blocs/search/search_cubit.dart';
import '../presentation/blocs/wishlist/wishlist_cubit.dart';
import '../presentation/screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class AuraLivingApp extends StatelessWidget {
  const AuraLivingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(getIt<IAuthRepository>()),
        ),
        BlocProvider<WishlistCubit>(
          create: (_) => WishlistCubit(
            cartRepository: getIt<ICartRepository>(),
            productRepository: getIt<IProductRepository>(),
          ),
        ),
        BlocProvider<CartCubit>(
          create: (_) => CartCubit(getIt<ICartRepository>()),
        ),
        BlocProvider<CatalogCubit>(
          create: (_) => CatalogCubit(getIt<IProductRepository>()),
        ),
        BlocProvider<SearchCubit>(
          create: (_) => SearchCubit(
            productRepository: getIt<IProductRepository>(),
            storage: getIt<LocalStorageService>(),
          ),
        ),
        BlocProvider<CheckoutCubit>(
          create: (_) => CheckoutCubit(getIt<IOrderRepository>()),
        ),
      ],
      child: MaterialApp(
        title: 'Aura Living',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
