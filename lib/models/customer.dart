class Customer {
  final int? id;
  final String? code;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String customerType;
  final double creditLimit;
  final double openingBalance;
  final double currentBalance;
  final String createdAt;

  Customer({
    this.id,
    this.code,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.customerType = 'Regular',
    this.creditLimit = 0,
    this.openingBalance = 0,
    this.currentBalance = 0,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'phone': phone,
        'email': email,
        'address': address,
        'customer_type': customerType,
        'credit_limit': creditLimit,
        'opening_balance': openingBalance,
        'current_balance': currentBalance,
        'created_at': createdAt,
      };

  factory Customer.fromMap(Map<String, dynamic> m) => Customer(
        id: m['id'] as int?,
        code: m['code'] as String?,
        name: m['name'] as String,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        customerType: m['customer_type'] as String? ?? 'Regular',
        creditLimit: (m['credit_limit'] as num?)?.toDouble() ?? 0,
        openingBalance: (m['opening_balance'] as num?)?.toDouble() ?? 0,
        currentBalance: (m['current_balance'] as num?)?.toDouble() ?? 0,
        createdAt: m['created_at'] as String,
      );
}
