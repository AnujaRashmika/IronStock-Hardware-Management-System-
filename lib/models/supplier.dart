class Supplier {
  final int? id;
  final String? code;
  final String name;
  final String? company;
  final String? phone;
  final String? email;
  final String? address;
  final String? taxNo;
  final double creditLimit;
  final double currentBalance;
  final String? notes;
  final String createdAt;

  Supplier({
    this.id,
    this.code,
    required this.name,
    this.company,
    this.phone,
    this.email,
    this.address,
    this.taxNo,
    this.creditLimit = 0,
    this.currentBalance = 0,
    this.notes,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'company': company,
        'phone': phone,
        'email': email,
        'address': address,
        'tax_no': taxNo,
        'credit_limit': creditLimit,
        'current_balance': currentBalance,
        'notes': notes,
        'created_at': createdAt,
      };

  factory Supplier.fromMap(Map<String, dynamic> m) => Supplier(
        id: m['id'] as int?,
        code: m['code'] as String?,
        name: m['name'] as String,
        company: m['company'] as String?,
        phone: m['phone'] as String?,
        email: m['email'] as String?,
        address: m['address'] as String?,
        taxNo: m['tax_no'] as String?,
        creditLimit: (m['credit_limit'] as num?)?.toDouble() ?? 0,
        currentBalance: (m['current_balance'] as num?)?.toDouble() ?? 0,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] as String,
      );
}
