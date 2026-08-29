class Product {
  final String id;
  final String code;
  final String name;
  final String category;
  final String brand;
  final String description;
  final String unit; // Piece, Box, Bag, Kg, Meter, Liter, Feet, Cubic Feet, Other
  final double purchasePrice;
  final double sellingPrice;
  final double wholesalePrice;
  double currentStock;
  final double minStock;
  final double reorderLevel;
  final String supplierId;
  final String supplierName;
  final String rackLocation;
  final int warrantyMonths;
  final double taxPercent;
  final bool discountAllowed;
  final String status; // Active, Inactive

  Product({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.brand = '',
    this.description = '',
    required this.unit,
    required this.purchasePrice,
    required this.sellingPrice,
    this.wholesalePrice = 0.0,
    required this.currentStock,
    this.minStock = 10.0,
    this.reorderLevel = 20.0,
    this.supplierId = '',
    this.supplierName = '',
    this.rackLocation = '',
    this.warrantyMonths = 0,
    this.taxPercent = 0.0,
    this.discountAllowed = true,
    this.status = 'Active',
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'brand': brand,
      'description': description,
      'unit': unit,
      'purchasePrice': purchasePrice,
      'sellingPrice': sellingPrice,
      'wholesalePrice': wholesalePrice,
      'currentStock': currentStock,
      'minStock': minStock,
      'reorderLevel': reorderLevel,
      'supplierId': supplierId,
      'supplierName': supplierName,
      'rackLocation': rackLocation,
      'warrantyMonths': warrantyMonths,
      'taxPercent': taxPercent,
      'discountAllowed': discountAllowed ? 1 : 0,
      'status': status,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      code: map['code'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      brand: map['brand'] ?? '',
      description: map['description'] ?? '',
      unit: map['unit'] ?? 'Piece',
      purchasePrice: (map['purchasePrice'] as num?)?.toDouble() ?? 0.0,
      sellingPrice: (map['sellingPrice'] as num?)?.toDouble() ?? 0.0,
      wholesalePrice: (map['wholesalePrice'] as num?)?.toDouble() ?? 0.0,
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      minStock: (map['minStock'] as num?)?.toDouble() ?? 10.0,
      reorderLevel: (map['reorderLevel'] as num?)?.toDouble() ?? 20.0,
      supplierId: map['supplierId'] ?? '',
      supplierName: map['supplierName'] ?? '',
      rackLocation: map['rackLocation'] ?? '',
      warrantyMonths: (map['warrantyMonths'] as num?)?.toInt() ?? 0,
      taxPercent: (map['taxPercent'] as num?)?.toDouble() ?? 0.0,
      discountAllowed: map['discountAllowed'] == 1 || map['discountAllowed'] == true,
      status: map['status'] ?? 'Active',
    );
  }
}
