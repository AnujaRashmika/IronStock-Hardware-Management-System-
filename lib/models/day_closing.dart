class DayClosing {
  final String id;
  final DateTime date;
  final String cashierName;
  final double openingCash;
  final double cashSales;
  final double cashRefunds;
  final double expenses;
  final double expectedCash;
  final double actualCash;
  final double difference;
  final String notes;

  DayClosing({
    required this.id,
    required this.date,
    required this.cashierName,
    required this.openingCash,
    required this.cashSales,
    required this.cashRefunds,
    required this.expenses,
    required this.expectedCash,
    required this.actualCash,
    required this.difference,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'cashierName': cashierName,
      'openingCash': openingCash,
      'cashSales': cashSales,
      'cashRefunds': cashRefunds,
      'expenses': expenses,
      'expectedCash': expectedCash,
      'actualCash': actualCash,
      'difference': difference,
      'notes': notes,
    };
  }

  factory DayClosing.fromMap(Map<String, dynamic> map) {
    return DayClosing(
      id: map['id'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      cashierName: map['cashierName'] ?? 'Cashier',
      openingCash: (map['openingCash'] as num?)?.toDouble() ?? 0.0,
      cashSales: (map['cashSales'] as num?)?.toDouble() ?? 0.0,
      cashRefunds: (map['cashRefunds'] as num?)?.toDouble() ?? 0.0,
      expenses: (map['expenses'] as num?)?.toDouble() ?? 0.0,
      expectedCash: (map['expectedCash'] as num?)?.toDouble() ?? 0.0,
      actualCash: (map['actualCash'] as num?)?.toDouble() ?? 0.0,
      difference: (map['difference'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }
}
