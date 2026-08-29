class WarrantyClaim {
  final String id;
  final String claimNo;
  final String invoiceNo;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String productId;
  final String productName;
  final String serialNumber;
  final DateTime purchaseDate;
  final DateTime dateReceived;
  final String issueDescription;
  String status; // Pending, Received, Under Inspection, Sent to Supplier, Repairing, Replaced, Completed, Rejected
  final String notes;

  WarrantyClaim({
    required this.id,
    required this.claimNo,
    required this.invoiceNo,
    required this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.productId,
    required this.productName,
    required this.serialNumber,
    required this.purchaseDate,
    required this.dateReceived,
    required this.issueDescription,
    this.status = 'Pending',
    this.notes = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'claimNo': claimNo,
      'invoiceNo': invoiceNo,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'productId': productId,
      'productName': productName,
      'serialNumber': serialNumber,
      'purchaseDate': purchaseDate.toIso8601String(),
      'dateReceived': dateReceived.toIso8601String(),
      'issueDescription': issueDescription,
      'status': status,
      'notes': notes,
    };
  }

  factory WarrantyClaim.fromMap(Map<String, dynamic> map) {
    return WarrantyClaim(
      id: map['id'] ?? '',
      claimNo: map['claimNo'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      serialNumber: map['serialNumber'] ?? '',
      purchaseDate: DateTime.tryParse(map['purchaseDate'] ?? '') ?? DateTime.now(),
      dateReceived: DateTime.tryParse(map['dateReceived'] ?? '') ?? DateTime.now(),
      issueDescription: map['issueDescription'] ?? '',
      status: map['status'] ?? 'Pending',
      notes: map['notes'] ?? '',
    );
  }
}
