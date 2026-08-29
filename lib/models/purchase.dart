import 'dart:convert';

class PurchaseItem {
  final String productId;
  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double purchasePrice;
  final double discount;
  final double total;

  PurchaseItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
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
      'purchasePrice': purchasePrice,
      'discount': discount,
      'total': total,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'Piece',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Purchase {
  final String id;
  final String purchaseNo;
  final String supplierInvoiceNo;
  final DateTime date;
  final String supplierId;
  final String supplierName;
  final double subtotal;
  final double discount;
  final double tax;
  final double totalAmount;
  final double paidAmount;
  final double creditAmount;
  final String paymentMethod;
  final List<PurchaseItem> items;
  final String notes;

  Purchase({
    required this.id,
    required this.purchaseNo,
    this.supplierInvoiceNo = '',
    required this.date,
    required this.supplierId,
    required this.supplierName,
    required this.subtotal,
    this.discount = 0.0,
    this.tax = 0.0,
    required this.totalAmount,
    required this.paidAmount,
    required this.creditAmount,
    this.paymentMethod = 'Cash',
    required this.items,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseNo': purchaseNo,
      'supplierInvoiceNo': supplierInvoiceNo,
      'date': date.toIso8601String(),
      'supplierId': supplierId,
      'supplierName': supplierName,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'totalAmount': totalAmount,
      'paidAmount': paidAmount,
      'creditAmount': creditAmount,
      'paymentMethod': paymentMethod,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
      'notes': notes,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map, {List<PurchaseItem>? items}) {
    return Purchase(
      id: map['id'] ?? '',
      purchaseNo: map['purchaseNo'] ?? '',
      supplierInvoiceNo: map['supplierInvoiceNo'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      tax: (map['tax'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (map['creditAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'Cash',
      items: items ?? [],
      notes: map['notes'] ?? '',
    );
  }
}
