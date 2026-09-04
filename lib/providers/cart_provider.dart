import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];
  int? customerId;
  String? customerName;
  /// Extra cart-level discount (manual). Item discounts are summed separately.
  double extraDiscount = 0;
  double tax = 0;
  double deliveryCharge = 0;

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;

  /// Sum of full prices (before any discounts).
  double get subtotal => _items.fold(0.0, (s, i) => s + i.lineGross);

  /// All discounts: per-line product discounts + optional extra.
  double get itemsDiscount => _items.fold(0.0, (s, i) => s + i.discount);
  double get discount => itemsDiscount + extraDiscount;

  double get total => subtotal - discount + tax + deliveryCharge;

  void addProduct(Product p, {double qty = 1}) {
    final existing = _items.indexWhere((i) => i.productId == p.id);
    final unitDiscount = p.discount > 0 ? p.discount : 0.0;
    if (existing >= 0) {
      _items[existing].quantity += qty;
      if (unitDiscount > 0) {
        _items[existing].discount = unitDiscount * _items[existing].quantity;
      }
    } else {
      _items.add(CartItem(
        productId: p.id!,
        productName: p.name,
        unit: p.unit,
        unitPrice: p.sellingPrice,
        quantity: qty,
        discount: unitDiscount * qty,
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
        final oldQty = _items[i].quantity;
        _items[i].quantity = qty;
        if (oldQty > 0 && _items[i].discount > 0) {
          final perUnit = _items[i].discount / oldQty;
          _items[i].discount = perUnit * qty;
        }
      }
      notifyListeners();
    }
  }

  void remove(int productId) {
    _items.removeWhere((e) => e.productId == productId);
    notifyListeners();
  }

  void setCustomer({int? id, String? name}) {
    customerId = id;
    customerName = name;
    notifyListeners();
  }

  void clearCustomer() {
    customerId = null;
    customerName = null;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    customerId = null;
    customerName = null;
    extraDiscount = 0;
    tax = 0;
    deliveryCharge = 0;
    notifyListeners();
  }
}
