
import 'package:test1/domain/entity/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmailAndPassword(String email, String password);
  Future<UserEntity> signUpWithEmailAndPassword(String email, String password, String name);
  Future<void> signOut();
  Future<void> updateThemeMode(String uid, String themeMode);
  Stream<UserEntity?> get authStateChanges;
}
