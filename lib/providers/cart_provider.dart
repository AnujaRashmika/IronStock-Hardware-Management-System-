import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? customerId;
  String? customerName;
  double discount = 0;
  double tax = 0;
  double deliveryCharge = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  double get subtotal => _items.fold(0, (s, i) => s + i.lineTotal);
  double get total => subtotal - discount + tax + deliveryCharge;

  void addProduct(Product p, {double qty = 1}) {
    final existing = _items.indexWhere((i) => i.productId == p.id);
    if (existing >= 0) {
      _items[existing].quantity += qty;
    } else {
      _items.add(CartItem(
        productId: p.id!,
        productName: p.name,
        unit: p.unit,
        unitPrice: p.sellingPrice,
        quantity: qty,
      ));
    }
    notifyListeners();
  }

  void updateQty(int productId, double qty) {
    final i = _items.indexWhere((e) => e.productId == productId);
    if (i >= 0) {
      if (qty <= 0) {
        _items.removeAt(i);
      } else {
        _items[i].quantity = qty;
      }
      notifyListeners();
    }
  }

  void remove(int productId) {
    _items.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    customerId = null;
    customerName = null;
    discount = 0;
    tax = 0;
    deliveryCharge = 0;
    notifyListeners();
  }
}
