import 'package:clean_arch_session/core/networking/api_error_handler.dart';
import 'package:clean_arch_session/feature/auth/domain/entities/register_entity.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/login_usecase.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/logout_usecase.dart';
import 'package:clean_arch_session/feature/auth/domain/usecases/register_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final RegisterUseCase _registerUseCase;
  final LogoutUseCase _logoutUseCase;

  AuthCubit(this._loginUseCase, this._registerUseCase, this._logoutUseCase)
    : super(AuthInitial());

  Future<void> login({required String email, required String password}) async {
    emit(AuthLoading());
    try {
      final message = await _loginUseCase(email: email, password: password);
      emit(AuthAuthenticated(message));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> register(RegisterEntity entity) async {
    emit(AuthLoading());
    try {
      final message = await _registerUseCase(entity);
      emit(AuthAuthenticated(message));
    } catch (error) {
      emit(AuthFailure(ApiErrorHandler.getMessage(error)));
    }
  }

  Future<void> logout() async {
    emit(AuthLoading());
    try {
      final message = await _logoutUseCase();
      emit(AuthLoggedOut(message: message));
    } catch (error) {
      emit(
        AuthLoggedOut(
          message: 'تم تسجيل الخروج محلياً. ${ApiErrorHandler.getMessage(error)}',
        ),
      );
    }
  }
}
