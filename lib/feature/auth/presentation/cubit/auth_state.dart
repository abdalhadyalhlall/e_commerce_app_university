part of 'auth_cubit.dart';

sealed class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String message;

  AuthAuthenticated(this.message);
}

class AuthLoggedOut extends AuthState {
  final String message;

  AuthLoggedOut({required this.message});
}

class AuthFailure extends AuthState {
  final String message;

  AuthFailure(this.message);
}
