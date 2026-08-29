class Delivery {
  final String id;
  final String deliveryNo;
  final String invoiceNo;
  final String customerId;
  final String customerName;
  final String phone;
  final String address;
  final DateTime deliveryDate;
  final DateTime expectedDate;
  final String driverName;
  final String vehicleNo;
  final double deliveryCharge;
  String status; // Pending, Scheduled, Out for Delivery, Delivered, Cancelled, Failed
  final String notes;
  final DateTime? deliveredDate;
  final String receivedBy;

  Delivery({
    required this.id,
    required this.deliveryNo,
    required this.invoiceNo,
    required this.customerId,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.deliveryDate,
    required this.expectedDate,
    this.driverName = '',
    this.vehicleNo = '',
    this.deliveryCharge = 0.0,
    this.status = 'Pending',
    this.notes = '',
    this.deliveredDate,
    this.receivedBy = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deliveryNo': deliveryNo,
      'invoiceNo': invoiceNo,
      'customerId': customerId,
      'customerName': customerName,
      'phone': phone,
      'address': address,
      'deliveryDate': deliveryDate.toIso8601String(),
      'expectedDate': expectedDate.toIso8601String(),
      'driverName': driverName,
      'vehicleNo': vehicleNo,
      'deliveryCharge': deliveryCharge,
      'status': status,
      'notes': notes,
      'deliveredDate': deliveredDate?.toIso8601String(),
      'receivedBy': receivedBy,
    };
  }

  factory Delivery.fromMap(Map<String, dynamic> map) {
    return Delivery(
      id: map['id'] ?? '',
      deliveryNo: map['deliveryNo'] ?? '',
      invoiceNo: map['invoiceNo'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      phone: map['phone'] ?? '',
      address: map['address'] ?? '',
      deliveryDate: DateTime.tryParse(map['deliveryDate'] ?? '') ?? DateTime.now(),
      expectedDate: DateTime.tryParse(map['expectedDate'] ?? '') ?? DateTime.now(),
      driverName: map['driverName'] ?? '',
      vehicleNo: map['vehicleNo'] ?? '',
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      status: map['status'] ?? 'Pending',
      notes: map['notes'] ?? '',
      deliveredDate: map['deliveredDate'] != null ? DateTime.tryParse(map['deliveredDate']) : null,
      receivedBy: map['receivedBy'] ?? '',
    );
  }
}
