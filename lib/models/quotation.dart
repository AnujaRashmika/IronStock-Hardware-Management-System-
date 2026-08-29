import 'dart:convert';

class QuotationItem {
  final String productId;
  final String productCode;
  final String productName;
  final String unit;
  final double quantity;
  final double unitPrice;
  final double discount;
  final double total;

  QuotationItem({
    required this.productId,
    required this.productCode,
    required this.productName,
    required this.unit,
    required this.quantity,
    required this.unitPrice,
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
      'discount': discount,
      'total': total,
    };
  }

  factory QuotationItem.fromMap(Map<String, dynamic> map) {
    return QuotationItem(
      productId: map['productId'] ?? '',
      productCode: map['productCode'] ?? '',
      productName: map['productName'] ?? '',
      unit: map['unit'] ?? 'Piece',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class Quotation {
  final String id;
  final String quotationNo;
  final DateTime date;
  final DateTime validityDate;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final double subtotal;
  final double discount;
  final double totalAmount;
  final String status; // Pending, Converted, Expired
  final String notes;
  final List<QuotationItem> items;

  Quotation({
    required this.id,
    required this.quotationNo,
    required this.date,
    required this.validityDate,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.subtotal,
    this.discount = 0.0,
    required this.totalAmount,
    this.status = 'Pending',
    this.notes = '',
    required this.items,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quotationNo': quotationNo,
      'date': date.toIso8601String(),
      'validityDate': validityDate.toIso8601String(),
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'subtotal': subtotal,
      'discount': discount,
      'totalAmount': totalAmount,
      'status': status,
      'notes': notes,
      'itemsJson': jsonEncode(items.map((i) => i.toMap()).toList()),
    };
  }

  factory Quotation.fromMap(Map<String, dynamic> map, {List<QuotationItem>? items}) {
    return Quotation(
      id: map['id'] ?? '',
      quotationNo: map['quotationNo'] ?? '',
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      validityDate: DateTime.tryParse(map['validityDate'] ?? '') ?? DateTime.now().add(const Duration(days: 14)),
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? 'Customer',
      customerPhone: map['customerPhone'] ?? '',
      subtotal: (map['subtotal'] as num?)?.toDouble() ?? 0.0,
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      notes: map['notes'] ?? '',
      items: items ?? [],
    );
  }
}
