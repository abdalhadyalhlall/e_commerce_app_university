import 'package:clean_arch_session/core/di/dependency_injection.dart';
import 'package:clean_arch_session/core/routes/routes.dart';
import 'package:clean_arch_session/feature/auth/presentation/cubit/auth_cubit.dart';
import 'package:clean_arch_session/feature/auth/presentation/ui/login_screen.dart';
import 'package:clean_arch_session/feature/auth/presentation/ui/register_screen.dart';
import 'package:clean_arch_session/feature/store/presentation/store_cubit.dart';
import 'package:clean_arch_session/feature/store/presentation/store_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AppRouter {
  Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
      case Routes.login:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<AuthCubit>(),
            child: const LoginScreen(),
          ),
        );
      case Routes.register:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (_) => getIt<AuthCubit>(),
            child: const RegisterScreen(),
          ),
        );
      case Routes.store:
        return MaterialPageRoute(
          builder: (_) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<AuthCubit>()),
              BlocProvider(create: (_) => getIt<StoreCubit>()),
            ],
            child: const StoreScreen(),
          ),
        );
      default:
        return null;
    }
  }
}
