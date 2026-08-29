class Supplier {
  final String id;
  final String code;
  final String name;
  final String company;
  final String phone;
  final String email;
  final String address;
  final String taxVatNo;
  final double openingBalance;
  double balance; // Positive balance means shop owes supplier
  final double creditLimit;
  final String notes;

  Supplier({
    required this.id,
    required this.code,
    required this.name,
    this.company = '',
    this.phone = '',
    this.email = '',
    this.address = '',
    this.taxVatNo = '',
    this.openingBalance = 0.0,
    this.balance = 0.0,
    this.creditLimit = 500000.0,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'company': company,
      'phone': phone,
      'email': email,
      'address': address,
      'taxVatNo': taxVatNo,
      'openingBalance': openingBalance,
      'balance': balance,
      'creditLimit': creditLimit,
      'notes': notes,
    };
  }

  factory Supplier.fromMap(Map<String, dynamic> map) {
    return Supplier(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      company: map['company'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      taxVatNo: map['taxVatNo'] ?? '',
      openingBalance: (map['openingBalance'] as num?)?.toDouble() ?? 0.0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      creditLimit: (map['creditLimit'] as num?)?.toDouble() ?? 500000.0,
      notes: map['notes'] ?? '',
    );
  }
}

class SupplierPayment {
  final String id;
  final String supplierId;
  final String supplierName;
  final double amount;
  final String paymentMethod;
  final String reference;
  final DateTime date;
  final String notes;

  SupplierPayment({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    required this.amount,
    required this.paymentMethod,
    this.reference = '',
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'reference': reference,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory SupplierPayment.fromMap(Map<String, dynamic> map) {
    return SupplierPayment(
      id: map['id'] ?? '',
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      reference: map['reference'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}
