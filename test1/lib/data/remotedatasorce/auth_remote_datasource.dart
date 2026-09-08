import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:test1/core/errors/autherrormessage.dart';
import 'package:test1/core/errors/failures.dart';
import 'package:test1/data/model/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  );
  Future<void> signOut();
  Future<void> updateThemeMode(String uid, String themeMode);
  Stream<User?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  AuthRemoteDataSourceImpl({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        return null;
      }

      try {
        final doc = await _firestore.collection('user').doc(user.uid).get();
        if (doc.exists) {
          return UserModel.fromSnapshot(doc);
        }
      } catch (e) {
        print("error on get user");
      }

      // Fallback user model if doc query failed or doc doesn't exist
      return UserModel(
        uid: user.uid,
        name:
            user.displayName ??
            (user.email != null && user.email!.contains('@')
                ? user.email!.split('@').first
                : 'User'),
        email: user.email ?? '',
      );
    } catch (e) {
      throw ServerFailure('Failed to fetch user data: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;

      try {
        final doc = await _firestore.collection('user').doc(uid).get();
        if (doc.exists) {
          return UserModel.fromSnapshot(doc);
        }
      } catch (a) {
        throw a.toString();
      }

      final name =
          credential.user?.displayName ??
          (email.contains('@') ? email.split('@').first : 'User');
      return UserModel(
        uid: uid,
        name: name,
        email: credential.user?.email ?? email,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserModel> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final uid = credential.user!.uid;
      final userModel = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        createdAt: DateTime.now(),
        themeMode: 'light',
      );

      // store user into collection "user"
      try {
        await _firestore.collection('user').doc(uid).set(userModel.toJson());
      } catch (e) {
        print("error storing user to collection: $e");
      }

      return userModel;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(getAuthErrorMessage(e.code));
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> updateThemeMode(String uid, String themeMode) async {
    print(
      "inside updarethememode   and the thememoed is : ${themeMode.toString()} and the uid is : ${uid.toString()}",
    );
    try {
      await _firestore.collection('user').doc(uid).set({
        'themeMode': themeMode,
      }, SetOptions(merge: true));
      print("them mode updated successfully");
    } catch (e) {
      print("Failed to update themeMode in firestore: $e");
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      throw ServerFailure('Failed to sign out: ${e.toString()}');
    }
  }
}
