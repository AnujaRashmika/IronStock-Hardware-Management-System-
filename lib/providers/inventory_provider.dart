import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';
import '../services/stock_service.dart';

class InventoryProvider extends ChangeNotifier {
  /// Set before navigating to Inventory to open with a filter.
  String? pendingFilter;

  final ProductRepository _repository = ProductRepository();
  List<Product> _products = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get totalProducts => _products.length;

  int get lowStockProducts =>
      _products.where((p) => p.stockQuantity > 0 && p.stockQuantity <= p.reorderLevel).length;

  int get outOfStockProducts =>
      _products.where((p) => p.stockQuantity <= 0).length;

  int get inStockProducts =>
      _products.where((p) => p.stockQuantity > p.reorderLevel).length;

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();
    try {
      _products = await _repository.getAll();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = e.toString();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadProducts() => load();
  Future<void> loadInventory() => load();

  /// Increase stock only (positive quantity).
  Future<bool> addStock(int productId, double quantity) async {
    if (quantity <= 0) return false;
    try {
      final p = _products.where((e) => e.id == productId).toList();
      final name = p.isNotEmpty ? p.first.name : 'Product';
      await StockService.instance.move(
        productId: productId,
        productName: name,
        type: 'adjustment',
        quantity: quantity,
        notes: 'Stock add',
      );
      await load();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }
}
