import 'dart:convert';

class SaleItem {
  final String productId;
  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double purchasePrice; // Saved for accurate profit calculation
  final double discount;
  final double total;

  SaleItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.purchasePrice,
    this.discount = 0.0,
    required this.total,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productCode': productCode,
      'productName': productName,
      'unit': unit,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'purchasePrice': purchasePrice,
      'discount': discount,
      'total': total,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'Piece',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalePaymentSplit {
  final String method; // Cash, Card, Bank Transfer, Credit
  final double amount;

  SalePaymentSplit({required this.method, required this.amount});

  Map<String, dynamic> toMap() => {'method': method, 'amount': amount};

  factory SalePaymentSplit.fromMap(Map<String, dynamic> map) => SalePaymentSplit(
        method: map['method'] ?? 'Cash',
        amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      );
}

class Sale {
  final String id;
  final String invoiceNo;
  final DateTime date;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double discount;
  final double tax;
  final double deliveryCharge;
  final double totalAmount;
  final double paidAmount;
  final double creditAmount;
  final String paymentStatus; // Paid, Partial, Unpaid/Credit
  final String primaryPaymentMethod; // Cash, Card, Bank Transfer, Credit, Mixed
  final List<SaleItem> items;
  final List<SalePaymentSplit> payments;
  final String notes;
  final String status; // Completed, Cancelled, Returned

  Sale({
    required this.id,
    required this.invoiceNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    this.deliveryCharge = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditAmount,
    required this.paymentStatus,
    required this.primaryPaymentMethod,
    required this.items,
    this.payments = const [],
    this.notes = '',
    this.status = 'Completed',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceNo': invoiceNo,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'deliveryCharge': deliveryCharge,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'creditAmount': creditAmount,
      'paymentStatus': paymentStatus,
      'primaryPaymentMethod': primaryPaymentMethod,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
      'paymentsJson': jsonEncode(payments.map((p) => p.toMap()).toList()),
      'notes': notes,
      'status': status,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map, {List<SaleItem>? items, List<SalePaymentSplit>? payments}) {
    return Sale(
      id: map['id'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Walk-in Customer',
      customerPhone: map['customerPhone'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['creditAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'Paid',
      primaryPaymentMethod: map['primaryPaymentMethod'] ?? 'Cash',
      items: items ?? [],
      payments: payments ?? [],
      notes: map['notes'] ?? '',
      status: map['status'] ?? 'Completed',
    );
  }
}
