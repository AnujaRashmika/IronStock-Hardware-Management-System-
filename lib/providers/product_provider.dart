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
      _products = await _repo.getAll();
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
      _products = q.isEmpty ? await _repo.getAll(activeOnly: true) : await _repo.search(q);
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

  Future<List<Product>> lowStock() => _repo.lowStock();
}
