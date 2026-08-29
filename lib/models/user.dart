class User {
  final String id;
  final String username;
  final String name;
  final String role; // Admin, Cashier, Store Keeper, Delivery Staff
  final String pinOrPassword;
  final List<String> permissions;
  final bool isActive;

  User({
    required this.id,
    required this.username,
    required this.name,
    required this.role,
    this.pinOrPassword = '1234',
    this.permissions = const [],
    this.isActive = true,
  });

  bool hasPermission(String perm) {
    if (role == 'Admin') return true;
    return permissions.contains(perm);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'role': role,
      'pinOrPassword': pinOrPassword,
      'permissions': permissions.join(','),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    final permsStr = map['permissions'] as String? ?? '';
    return User(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'Cashier',
      pinOrPassword: map['pinOrPassword'] ?? '1234',
      permissions: permsStr.isNotEmpty ? permsStr.split(',') : [],
      isActive: map['isActive'] == 1 || map['isActive'] == true,
    );
  }
}
