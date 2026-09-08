
import 'package:test1/domain/entity/user_entity.dart';
import 'package:test1/domain/repository/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;
  SignInUseCase(this.repository);

  Future<UserEntity> call(String email, String password) {
    return repository.signInWithEmailAndPassword(email, password);
  }
}

class SignUpUseCase {
  final AuthRepository repository;
  SignUpUseCase(this.repository);

  Future<UserEntity> call(String email, String password, String name) {
    return repository.signUpWithEmailAndPassword(email, password, name);
  }
}

class SignOutUseCase {
  final AuthRepository repository;
  SignOutUseCase(this.repository);

  Future<void> call() {
    return repository.signOut();
  }
}

class GetCurrentUserUseCase {
  final AuthRepository repository;
  GetCurrentUserUseCase(this.repository);

  Future<UserEntity?> call() {
    return repository.getCurrentUser();
  }
}
