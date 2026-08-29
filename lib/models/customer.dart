class Customer {
  final String id;
  final String code;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String customerType; // Walk-in, Regular, Contractor, Company, Builder
  final double creditLimit;
  double balance; // Positive balance means outstanding owed to shop
  final double openingBalance;
  final String notes;

  Customer({
    required this.id,
    required this.code,
    required this.name,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.customerType = 'Regular',
    this.creditLimit = 50000.0,
    this.balance = 0.0,
    this.openingBalance = 0.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'customerType': customerType,
      'creditLimit': creditLimit,
      'balance': balance,
      'openingBalance': openingBalance,
      'notes': notes,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      customerType: map['customerType'] ?? 'Regular',
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 50000.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] ?? '',
    );
  }
}

class CustomerPayment {
  final String id;
  final String customerId;
  final String customerName;
  final double amount;
  final String paymentMethod; // Cash, Card, Bank Transfer
  final String reference;
  final DateTime date;
  final String notes;

  CustomerPayment({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.amount,
    required this.paymentMethod,
    this.reference = '',
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory CustomerPayment.fromMap(Map<String, dynamic> map) {
    return CustomerPayment(
      id: map['id'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      reference: map['reference'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}
