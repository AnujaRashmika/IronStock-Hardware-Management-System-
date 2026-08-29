class ExpenseCategory {
  final String id;
  final String name;

  ExpenseCategory({required this.id, required this.name});

  Map<String, dynamic> toMap() => {'id': id, 'name': name};
  factory ExpenseCategory.fromMap(Map<String, dynamic> map) => ExpenseCategory(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
      );
}

class Expense {
  final String id;
  final String categoryName; // Transport, Electricity, Water, Rent, Salary, Fuel, Maintenance, Delivery, Telephone, Stationery, Other
  final String description;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String reference;
  final String notes;

  Expense({
    required this.id,
    required this.categoryName,
    required this.description,
    required this.amount,
    required this.date,
    this.paymentMethod = 'Cash',
    this.reference = '',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categoryName': categoryName,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'paymentMethod': paymentMethod,
      'reference': reference,
      'notes': notes,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map) {
    return Expense(
      id: map['id'] ?? '',
      categoryName: map['categoryName'] ?? 'Other',
      description: map['description'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      reference: map['reference'] ?? '',
      notes: map['notes'] ?? '',
    );
  }
}
