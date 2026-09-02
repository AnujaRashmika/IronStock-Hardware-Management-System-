class Product {
  final int? id;
  final String? sku;
  final String name;
  final int? categoryId;
  final String? brand;
  final String? description;
  final String unit;
  final double purchasePrice;
  final double sellingPrice;
  final double discount; // per-unit discount amount
  final double wholesalePrice;
  final double stockQuantity;
  final double minStock;
  final double reorderLevel;
  final int? supplierId;
  final String? rackLocation;
  final int warrantyMonths;
  final double taxRate;
  final String? barcode;
  final bool isActive;
  final String createdAt;
  final String? updatedAt;

  Product({
    this.id,
    this.sku,
    required this.name,
    this.categoryId,
    this.brand,
    this.description,
    this.unit = 'Piece',
    this.purchasePrice = 0,
    this.sellingPrice = 0,
    this.discount = 0,
    this.wholesalePrice = 0,
    this.stockQuantity = 0,
    this.minStock = 5,
    this.reorderLevel = 10,
    this.supplierId,
    this.rackLocation,
    this.warrantyMonths = 0,
    this.taxRate = 0,
    this.barcode,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isLowStock => stockQuantity > 0 && stockQuantity <= reorderLevel;
  bool get isOutOfStock => stockQuantity <= 0;

  double get effectivePrice => sellingPrice - (discount > 0 ? discount : 0);

  Map<String, dynamic> toMap() => {
        'id': id,
        'sku': sku,
        'name': name,
        'category_id': categoryId,
        'brand': brand,
        'description': description,
        'unit': unit,
        'purchase_price': purchasePrice,
        'selling_price': sellingPrice,
        'discount': discount,
        'wholesale_price': wholesalePrice,
        'stock_quantity': stockQuantity,
        'min_stock': minStock,
        'reorder_level': reorderLevel,
        'supplier_id': supplierId,
        'rack_location': rackLocation,
        'warranty_months': warrantyMonths,
        'tax_rate': taxRate,
        'barcode': barcode,
        'is_active': isActive ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory Product.fromMap(Map<String, dynamic> m) => Product(
        id: m['id'] as int?,
        sku: m['sku'] as String?,
        name: m['name'] as String,
        categoryId: m['category_id'] as int?,
        brand: m['brand'] as String?,
        description: m['description'] as String?,
        unit: m['unit'] as String? ?? 'Piece',
        purchasePrice: (m['purchase_price'] as num?)?.toDouble() ?? 0,
        sellingPrice: (m['selling_price'] as num?)?.toDouble() ?? 0,
        discount: (m['discount'] as num?)?.toDouble() ?? 0,
        wholesalePrice: (m['wholesale_price'] as num?)?.toDouble() ?? 0,
        stockQuantity: (m['stock_quantity'] as num?)?.toDouble() ?? 0,
        minStock: (m['min_stock'] as num?)?.toDouble() ?? 5,
        reorderLevel: (m['reorder_level'] as num?)?.toDouble() ?? 10,
        supplierId: m['supplier_id'] as int?,
        rackLocation: m['rack_location'] as String?,
        warrantyMonths: m['warranty_months'] as int? ?? 0,
        taxRate: (m['tax_rate'] as num?)?.toDouble() ?? 0,
        barcode: m['barcode'] as String?,
        isActive: (m['is_active'] as int?) == 1,
        createdAt: m['created_at'] as String,
        updatedAt: m['updated_at'] as String?,
      );

  Product copyWith({double? stockQuantity}) => Product(
        id: id,
        sku: sku,
        name: name,
        categoryId: categoryId,
        brand: brand,
        description: description,
        unit: unit,
        purchasePrice: purchasePrice,
        sellingPrice: sellingPrice,
        discount: discount,
        wholesalePrice: wholesalePrice,
        stockQuantity: stockQuantity ?? this.stockQuantity,
        minStock: minStock,
        reorderLevel: reorderLevel,
        supplierId: supplierId,
        rackLocation: rackLocation,
        warrantyMonths: warrantyMonths,
        taxRate: taxRate,
        barcode: barcode,
        isActive: isActive,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
