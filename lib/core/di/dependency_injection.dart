import 'package:clean_arch_session/core/networking/api_service.dart';
import 'package:clean_arch_session/feature/auth/data/auth_repo_impl.dart';
import 'package:clean_arch_session/feature/auth/domain/repositories/auth_repo.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/login_usecase.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/register_usecase.dart';
import 'package:clean_arch_session/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:clean_arch_session/feature/store/data/store_repository_impl.dart';
import 'package:clean_arch_session/feature/store/data/order_realtime_service.dart';
import 'package:clean_arch_session/feature/store/domain/repositories/store_repository.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/cart_usecases.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/catalog_usecases.dart';
import 'package:clean_arch_session/feature/store/domain/usecases/order_usecases.dart';
import 'package:clean_arch_session/feature/store/presentation/store_cubit.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

final getIt = GetIt.instance;

void setupGetIt() {
  getIt.registerLazySingleton<Dio>(() => Dio());
  getIt.registerLazySingleton<ApiService>(() => ApiService(getIt()));
  getIt.registerLazySingleton<AuthRepo>(() => AuthRepoImpl(getIt()));
  getIt.registerLazySingleton<LoginUseCase>(() => LoginUseCase(getIt()));
  getIt.registerLazySingleton<RegisterUseCase>(() => RegisterUseCase(getIt()));
  getIt.registerLazySingleton<LogoutUseCase>(() => LogoutUseCase(getIt()));
  getIt.registerFactory<AuthCubit>(() => AuthCubit(getIt(), getIt(), getIt()));
  getIt.registerLazySingleton<StoreRepository>(
    () => StoreRepositoryImpl(getIt()),
  );
  getIt.registerFactory<OrderRealtimeService>(
    () => OrderRealtimeService(getIt()),
  );
  getIt.registerLazySingleton<CatalogUseCases>(() => CatalogUseCases(getIt()));
  getIt.registerLazySingleton<CartUseCases>(() => CartUseCases(getIt()));
  getIt.registerLazySingleton<OrderUseCases>(() => OrderUseCases(getIt()));
  getIt.registerFactory<StoreCubit>(
    () => StoreCubit(getIt(), getIt(), getIt(), getIt()),
  );
}
