class StockMovement {
  final String id;
  final String productId;
  final String productName;
  final String type; // Purchase, Sale, Return, Damage, Adjustment
  final double quantityDelta; // e.g., +50 or -10
  final double previousStock;
  final double newStock;
  final DateTime date;
  final String reference; // Purchase #, Invoice #, Return #, etc.
  final String reason;

  StockMovement({
    required this.id,
    required this.productId,
    required this.productName,
    required this.type,
    required this.quantityDelta,
    required this.previousStock,
    required this.newStock,
    required this.date,
    this.reference = '',
    this.reason = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'type': type,
      'quantityDelta': quantityDelta,
      'previousStock': previousStock,
      'newStock': newStock,
      'date': date.toIso8601String(),
      'reference': reference,
      'reason': reason,
    };
  }

  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      type: map['type'] ?? 'Adjustment',
      quantityDelta: (map['quantityDelta'] as num?)?.toDouble() ?? 0.0,
      previousStock: (map['previousStock'] as num?)?.toDouble() ?? 0.0,
      newStock: (map['newStock'] as num?)?.toDouble() ?? 0.0,
      date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
      reference: map['reference'] ?? '',
      reason: map['reason'] ?? '',
    );
  }
}
