import 'package:clean_arch_session/feature/auth/domain/repositories/auth_repo.dart';

class LoginUseCase {
  final AuthRepo _authRepo;

  LoginUseCase(this._authRepo);

  Future<String> call({required String email, required String password}) {
    return _authRepo.login(email: email, password: password);
  }
}
