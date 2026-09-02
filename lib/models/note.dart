class Note {
  final int? id;
  final String title;
  final String content;
  final String createdAt;
  final String? updatedAt;

  Note({
    this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
  });

  factory Note.fromMap(Map<String, dynamic> m) => Note(
        id: m['id'] as int?,
        title: m['title']?.toString() ?? '',
        content: m['content']?.toString() ?? '',
        createdAt: m['created_at']?.toString() ?? '',
        updatedAt: m['updated_at']?.toString(),
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'content': content,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}
