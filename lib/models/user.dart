class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String role;
  final bool isActive;
  final String? permissions;
  final String createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.role = 'cashier',
    this.isActive = true,
    this.permissions,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'username': username,
        'password': password,
        'full_name': fullName,
        'role': role,
        'is_active': isActive ? 1 : 0,
        'permissions': permissions,
        'created_at': createdAt,
      };

  factory User.fromMap(Map<String, dynamic> m) => User(
        id: m['id'] as int?,
        username: m['username'] as String,
        password: m['password'] as String,
        fullName: m['full_name'] as String,
        role: m['role'] as String? ?? 'cashier',
        isActive: (m['is_active'] as int?) == 1,
        permissions: m['permissions'] as String?,
        createdAt: m['created_at'] as String,
      );

  bool get isAdmin => role == 'admin';
}
