class CartItem {
  final int productId;
  final String productName;
  final String unit;
  final double unitPrice;
  double quantity;
  double discount; // total line discount amount (unit discount × qty)

  CartItem({
    required this.productId,
    required this.productName,
    required this.unit,
    required this.unitPrice,
    this.quantity = 1,
    this.discount = 0,
  });

  /// Full price before discount (shown on cart line right side).
  double get lineGross => unitPrice * quantity;

  /// Net after line discount (used when computing order totals).
  double get lineNet => lineGross - discount;
}
