import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

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
}
