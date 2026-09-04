import 'package:flutter/material.dart';
import '../models/product.dart';
import '../repositories/product_repository.dart';

class ProductProvider extends ChangeNotifier {
  final _repo = ProductRepository();
  List<Product> _products = [];
  bool loading = false;
  String? error;

  List<Product> get products => _products;
  bool get isLoading => loading;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    try {
      _products = await _repo.getAll(activeOnly: false);
      error = null;
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<void> loadProducts() => load();

  Future<void> search(String q) async {
    loading = true;
    notifyListeners();
    try {
      if (q.isEmpty) {
        _products = await _repo.getAll(activeOnly: false);
      } else {
        _products = await _repo.search(q);
      }
    } catch (e) {
      error = e.toString();
    }
    loading = false;
    notifyListeners();
  }

  Future<bool> add(Product p) async {
    try {
      await _repo.insert(p);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> update(Product p) async {
    try {
      await _repo.update(p);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleActive(Product p) async {
    try {
      final updated = Product(
        id: p.id,
        sku: p.sku,
        name: p.name,
        categoryId: p.categoryId,
        brand: p.brand,
        description: p.description,
        unit: p.unit,
        purchasePrice: p.purchasePrice,
        sellingPrice: p.sellingPrice,
        discount: p.discount,
        wholesalePrice: p.wholesalePrice,
        stockQuantity: p.stockQuantity,
        minStock: p.minStock,
        reorderLevel: p.reorderLevel,
        supplierId: p.supplierId,
        rackLocation: p.rackLocation,
        warrantyMonths: p.warrantyMonths,
        taxRate: p.taxRate,
        barcode: p.barcode,
        isActive: !p.isActive,
        createdAt: p.createdAt,
        updatedAt: DateTime.now().toIso8601String(),
      );
      await _repo.update(updated);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> delete(int id) async {
    try {
      await _repo.hardDelete(id);
      await load();
      return true;
    } catch (e) {
      error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Product>> lowStock() => _repo.lowStock();
}
