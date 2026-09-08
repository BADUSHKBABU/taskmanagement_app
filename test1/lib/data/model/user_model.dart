import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:test1/domain/entity/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.uid,
    required super.name,
    required super.email,
    super.createdAt,
    super.themeMode = 'light',
  });

  factory UserModel.fromJson(Map<String, dynamic> map, String uid) {
    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(map['createdAt']);
      }
    }

    return UserModel(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      createdAt: parsedCreatedAt,
      themeMode: map['themeMode'] as String? ?? 'light',
    );
  }

  factory UserModel.fromSnapshot(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromJson(data, doc.id);
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'themeMode': themeMode,
    };
  }

  factory UserModel.fromEntity(UserEntity entity) {
    return UserModel(
      uid: entity.uid,
      name: entity.name,
      email: entity.email,
      createdAt: entity.createdAt,
      themeMode: entity.themeMode,
    );
  }
}
