class AppConstants {
  AppConstants._();
  static const String appName = 'Hardware Store Management';
  static const String currency = 'LKR';
  static const String defaultAdminUsername = 'anuja';
  static const String defaultAdminPassword = 'anuja123';
  static const List<String> units = [
    'Piece', 'Box', 'Bag', 'Kg', 'Meter', 'Liter', 'Feet', 'Cubic Feet', 'Pack', 'Other'
  ];
  static const List<String> paymentMethods = [
    'Cash', 'Card', 'Bank Transfer', 'Credit', 'Mixed'
  ];
  static const List<String> returnReasons = [
    'Wrong item', 'Damaged', 'Customer changed mind', 'Defective', 'Other'
  ];
  static const List<String> deliveryStatuses = [
    'Pending', 'Scheduled', 'Out for Delivery', 'Delivered', 'Cancelled', 'Failed'
  ];
  static const List<String> warrantyClaimStatuses = [
    'Pending', 'Completed', 'Rejected'
  ];
}
