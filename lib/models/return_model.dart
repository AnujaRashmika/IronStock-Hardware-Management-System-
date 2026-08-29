import 'dart:convert';

class ReturnItem {
  final String productId;
  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final String reason; // Wrong item, Damaged, Customer changed mind, Defective, Other
  final bool isDamaged;
  final double total;

  ReturnItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
    required this.reason,
    required this.isDamaged,
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
      'reason': reason,
      'isDamaged': isDamaged ? 1 : 0,
      'total': total,
    };
  }

  factory ReturnItem.fromMap(Map<String, dynamic> map) {
    return ReturnItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'Piece',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      reason: map['reason'] ?? 'Defective',
      isDamaged: map['isDamaged'] == 1 || map['isDamaged'] == true,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class SalesReturn {
  final String id;
  final String returnNo;
  final String invoiceNo;
  final DateTime date;
  final String customerId;
  final String customerName;
  final double totalAmount;
  final String refundMethod; // Cash, Card, Bank Transfer, Customer Credit
  final String notes;
  final List<ReturnItem> items;

  SalesReturn({
    required this.id,
    required this.returnNo,
    required this.invoiceNo,
    required this.date,
    required this.customerId,
    required this.customerName,
    required this.totalAmount,
    required this.refundMethod,
    this.notes = '',
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnNo': returnNo,
      'invoiceNo': invoiceNo,
      'date': date.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'refundMethod': refundMethod,
      'notes': notes,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory SalesReturn.fromMap(Map<String, dynamic> map, {List<ReturnItem>? items}) {
    return SalesReturn(
      id: map['id'] ?? '',
      returnNo: map['returnNo'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Customer',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      refundMethod: map['refundMethod'] ?? 'Cash',
      notes: map['notes'] ?? '',
      items: items ?? [],
    );
  }
}

class RefundRecord {
  final String id;
  final String returnNo;
  final String invoiceNo;
  final String customerName;
  final double amount;
  final String refundMethod; // Cash, Card, Bank Transfer, Customer Credit
  final DateTime date;
  final String notes;

  RefundRecord({
    required this.id,
    required this.returnNo,
    required this.invoiceNo,
    required this.customerName,
    required this.amount,
    required this.refundMethod,
    required this.date,
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'returnNo': returnNo,
      'invoiceNo': invoiceNo,
      'customerName': customerName,
      'amount': amount,
      'refundMethod': refundMethod,
      'date': date.toIso8601String(),
      'notes': notes,
    };
  }

  factory RefundRecord.fromMap(Map<String, dynamic> map) {
    return RefundRecord(
      id: map['id'] ?? '',
      returnNo: map['returnNo'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      customerName: map['customerName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      refundMethod: map['refundMethod'] ?? 'Cash',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      notes: map['notes'] ?? '',
    );
  }
}
