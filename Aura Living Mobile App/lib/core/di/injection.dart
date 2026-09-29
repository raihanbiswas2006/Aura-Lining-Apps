import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/datasources/local_storage_service.dart';
import '../../data/repositories_impl/firebase_auth_repository.dart';
import '../../data/repositories_impl/firebase_order_repository.dart';
import '../../data/repositories_impl/firebase_product_repository.dart';
import '../../data/repositories_impl/mock_cart_repository.dart';
import '../../domain/repositories/i_auth_repository.dart';
import '../../domain/repositories/i_cart_repository.dart';
import '../../domain/repositories/i_order_repository.dart';
import '../../domain/repositories/i_product_repository.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);

  // Data sources
  final localStorage = LocalStorageService(getIt<SharedPreferences>());
  getIt.registerSingleton<LocalStorageService>(localStorage);

  // Repositories (Firebase with local cache fallback)
  getIt.registerLazySingleton<IProductRepository>(
    () => FirebaseProductRepository(),
  );

  getIt.registerLazySingleton<ICartRepository>(
    () => MockCartRepository(getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<IAuthRepository>(
    () => FirebaseAuthRepository(storage: getIt<LocalStorageService>()),
  );

  getIt.registerLazySingleton<IOrderRepository>(
    () => FirebaseOrderRepository(storage: getIt<LocalStorageService>()),
  );
}
