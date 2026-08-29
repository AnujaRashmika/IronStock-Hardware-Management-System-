class AuditLog {
  final String id;
  final String username;
  final String action;
  final String details;
  final DateTime date;
  final String reference;

  AuditLog({
    required this.id,
    required this.username,
    required this.action,
    required this.details,
    required this.date,
    this.reference = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'action': action,
      'details': details,
      'date': date.toIso8601String(),
      'reference': reference,
    };
  }

  factory AuditLog.fromMap(Map<String, dynamic> map) {
    return AuditLog(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      action: map['action'] ?? '',
      details: map['details'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      reference: map['reference'] ?? '',
    );
  }
}
