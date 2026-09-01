class CartItem {
  final int productId;
  final String productName;
  final String unit;
  final double unitPrice;
  double quantity;
  double discount;

  CartItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
  });

  double get lineTotal => (unitPrice * quantity) - discount;
}
