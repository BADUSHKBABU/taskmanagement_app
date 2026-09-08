class UserEntity {
  final String uid;
  final String name;
  final String email;
  final DateTime? createdAt;
  final String themeMode;

  const UserEntity({
    required this.uid,
    required this.name,
    required this.email,
    this.createdAt,
    this.themeMode = 'light',
  });
}
