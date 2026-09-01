class Category {
  final int? id;
  final String name;
  final String? description;
  final bool isActive;
  final String createdAt;

  Category({this.id, required this.name, this.description, this.isActive = true, required this.createdAt});

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'description': description,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
      };

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as int?,
        name: m['name'] as String,
        description: m['description'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: m['created_at'] as String,
      );
}
