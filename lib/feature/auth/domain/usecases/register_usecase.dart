import 'package:clean_arch_session/feature/auth/domain/entities/register_entity.dart';
import 'package:clean_arch_session/feature/auth/domain/repositories/auth_repo.dart';

class RegisterUseCase {
  final AuthRepo _authRepo;

  RegisterUseCase(this._authRepo);

  Future<String> call(RegisterEntity entity) async {
    return _authRepo.register(entity);
  }
}
