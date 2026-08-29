import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../database/db_helper.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../models/customer.dart';
import '../models/supplier.dart';
import '../models/sale.dart';
import '../models/purchase.dart';
import '../models/quotation.dart';
import '../models/return_model.dart';
import '../models/warranty.dart';
import '../models/delivery.dart';
import '../models/expense.dart';
import '../models/stock_movement.dart';
import '../models/day_closing.dart';
import '../models/user.dart';
import '../models/audit_log.dart';
import '../models/shop_settings.dart';

class CartItem {
  final Product product;
  double quantity;
  double unitPrice;
  double discount;

  CartItem({
    required this.product,
    this.quantity = 1.0,
    required this.unitPrice,
    this.discount = 0.0,
  });

  double get total => (quantity * unitPrice) - discount;
}

class HeldSale {
  final String id;
  final String label;
  final DateTime date;
  final Customer customer;
  final List<CartItem> cartItems;
  final double discount;
  final double deliveryCharge;

  HeldSale({
    required this.id,
    required this.label,
    required this.date,
    required this.customer,
    required this.cartItems,
    this.discount = 0.0,
    this.deliveryCharge = 0.0,
  });
}

class AppProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  // Data Collections
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Customer> _customers = [];
  List<CustomerPayment> _customerPayments = [];
  List<Supplier> _suppliers = [];
  List<SupplierPayment> _supplierPayments = [];
  List<Sale> _sales = [];
  List<Purchase> _purchases = [];
  List<Quotation> _quotations = [];
  List<SalesReturn> _salesReturns = [];
  List<RefundRecord> _refunds = [];
  List<WarrantyClaim> _warrantyClaims = [];
  List<Delivery> _deliveries = [];
  List<Expense> _expenses = [];
  List<ExpenseCategory> _expenseCategories = [];
  List<StockMovement> _stockMovements = [];
  List<DayClosing> _dayClosings = [];
  List<User> _users = [];
  List<AuditLog> _auditLogs = [];
  ShopSettings _shopSettings = ShopSettings();

  // Active User
  User? _currentUser;
  User? get currentUser => _currentUser;

  // POS State
  List<CartItem> _cart = [];
  Customer _selectedCustomer = Customer(
    id: 'cust-0',
    code: 'CUST-000',
    name: 'Walk-in Customer',
    customerType: 'Walk-in',
  );
  double _cartDiscount = 0.0;
  double _cartDeliveryCharge = 0.0;
  final List<HeldSale> _heldSales = [];

  // Navigation State
  String _currentScreen = 'dashboard';

  // Getters
  List<Product> get products => _products;
  List<Category> get categories => _categories;
  List<Customer> get customers => _customers;
  List<CustomerPayment> get customerPayments => _customerPayments;
  List<Supplier> get suppliers => _suppliers;
  List<SupplierPayment> get supplierPayments => _supplierPayments;
  List<Sale> get sales => _sales;
  List<Purchase> get purchases => _purchases;
  List<Quotation> get quotations => _quotations;
  List<SalesReturn> get salesReturns => _salesReturns;
  List<RefundRecord> get refunds => _refunds;
  List<WarrantyClaim> get warrantyClaims => _warrantyClaims;
  List<Delivery> get deliveries => _deliveries;
  List<Expense> get expenses => _expenses;
  List<ExpenseCategory> get expenseCategories => _expenseCategories;
  List<StockMovement> get stockMovements => _stockMovements;
  List<DayClosing> get dayClosings => _dayClosings;
  List<User> get users => _users;
  List<AuditLog> get auditLogs => _auditLogs;
  ShopSettings get shopSettings => _shopSettings;

  // Currency Getters & Formatters
  String get currency => _shopSettings.currency;
  String formatCurrency(double amount) => '$currency ${NumberFormat('#,##0.00').format(amount)}';
  String formatAmount(double amount) => NumberFormat('#,##0.00').format(amount);

  List<CartItem> get cart => _cart;
  Customer get selectedCustomer => _selectedCustomer;
  double get cartDiscount => _cartDiscount;
  double get cartDeliveryCharge => _cartDeliveryCharge;
  List<HeldSale> get heldSales => _heldSales;

  String get currentScreen => _currentScreen;

  void setScreen(String screen) {
    _currentScreen = screen;
    notifyListeners();
  }

  AppProvider() {
    loadAllData();
  }

  Future<void> loadAllData() async {
    _isLoading = true;
    notifyListeners();

    try {
      final catMaps = await _db.queryAll('categories');
      _categories = catMaps.map((m) => Category.fromMap(m)).toList();

      final prodMaps = await _db.queryAll('products');
      _products = prodMaps.map((m) => Product.fromMap(m)).toList();

      final custMaps = await _db.queryAll('customers');
      _customers = custMaps.map((m) => Customer.fromMap(m)).toList();

      final custPayMaps = await _db.queryAll('customer_payments');
      _customerPayments = custPayMaps.map((m) => CustomerPayment.fromMap(m)).toList();

      final supMaps = await _db.queryAll('suppliers');
      _suppliers = supMaps.map((m) => Supplier.fromMap(m)).toList();

      final supPayMaps = await _db.queryAll('supplier_payments');
      _supplierPayments = supPayMaps.map((m) => SupplierPayment.fromMap(m)).toList();

      final saleMaps = await _db.queryAll('sales');
      _sales = saleMaps.map((m) {
        List<SaleItem> items = [];
        List<SalePaymentSplit> payments = [];
        if (m['itemsJson'] != null) {
          final List list = jsonDecode(m['itemsJson']);
          items = list.map((i) => SaleItem.fromMap(Map<String, dynamic>.from(i))).toList();
        }
        if (m['paymentsJson'] != null) {
          final List list = jsonDecode(m['paymentsJson']);
          payments = list.map((p) => SalePaymentSplit.fromMap(Map<String, dynamic>.from(p))).toList();
        }
        return Sale.fromMap(m, items: items, payments: payments);
      }).toList();

      final purMaps = await _db.queryAll('purchases');
      _purchases = purMaps.map((m) {
        List<PurchaseItem> items = [];
        if (m['itemsJson'] != null) {
          final List list = jsonDecode(m['itemsJson']);
          items = list.map((i) => PurchaseItem.fromMap(Map<String, dynamic>.from(i))).toList();
        }
        return Purchase.fromMap(m, items: items);
      }).toList();

      final qMaps = await _db.queryAll('quotations');
      _quotations = qMaps.map((m) {
        List<QuotationItem> items = [];
        if (m['itemsJson'] != null) {
          final List list = jsonDecode(m['itemsJson']);
          items = list.map((i) => QuotationItem.fromMap(Map<String, dynamic>.from(i))).toList();
        }
        return Quotation.fromMap(m, items: items);
      }).toList();

      final retMaps = await _db.queryAll('sales_returns');
      _salesReturns = retMaps.map((m) {
        List<ReturnItem> items = [];
        if (m['itemsJson'] != null) {
          final List list = jsonDecode(m['itemsJson']);
          items = list.map((i) => ReturnItem.fromMap(Map<String, dynamic>.from(i))).toList();
        }
        return SalesReturn.fromMap(m, items: items);
      }).toList();

      final refMaps = await _db.queryAll('refund_records');
      _refunds = refMaps.map((m) => RefundRecord.fromMap(m)).toList();

      final wMaps = await _db.queryAll('warranty_claims');
      _warrantyClaims = wMaps.map((m) => WarrantyClaim.fromMap(m)).toList();

      final delMaps = await _db.queryAll('deliveries');
      _deliveries = delMaps.map((m) => Delivery.fromMap(m)).toList();

      final expCatMaps = await _db.queryAll('expense_categories');
      _expenseCategories = expCatMaps.map((m) => ExpenseCategory.fromMap(m)).toList();

      final expMaps = await _db.queryAll('expenses');
      _expenses = expMaps.map((m) => Expense.fromMap(m)).toList();

      final smMaps = await _db.queryAll('stock_movements');
      _stockMovements = smMaps.map((m) => StockMovement.fromMap(m)).toList();

      final dcMaps = await _db.queryAll('day_closings');
      _dayClosings = dcMaps.map((m) => DayClosing.fromMap(m)).toList();

      final uMaps = await _db.queryAll('users');
      _users = uMaps.map((m) => User.fromMap(m)).toList();
      if (_users.isNotEmpty) {
        _currentUser = _users.firstWhere((u) => u.role == 'Admin', orElse: () => _users.first);
      }

      final logMaps = await _db.queryAll('audit_logs');
      _auditLogs = logMaps.map((m) => AuditLog.fromMap(m)).toList();

      final setMaps = await _db.queryAll('settings');
      if (setMaps.isNotEmpty) {
        _shopSettings = ShopSettings.fromMap(setMaps.first);
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Auth Management
  bool login(String username, String pin) {
    try {
      final user = _users.firstWhere(
        (u) => u.username.toLowerCase() == username.toLowerCase() && u.pinOrPassword == pin && u.isActive,
      );
      _currentUser = user;
      addAuditLog('User Login', 'User ${user.name} logged into system.', reference: user.username);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    if (_currentUser != null) {
      addAuditLog('User Logout', 'User ${_currentUser!.name} logged out.', reference: _currentUser!.username);
    }
    _currentUser = null;
    notifyListeners();
  }

  // Audit Logger
  Future<void> addAuditLog(String action, String details, {String reference = ''}) async {
    final log = AuditLog(
      id: 'log-${DateTime.now().millisecondsSinceEpoch}',
      username: _currentUser?.username ?? 'System',
      action: action,
      details: details,
      date: DateTime.now(),
      reference: reference,
    );
    _auditLogs.insert(0, log);
    await _db.insert('audit_logs', log.toMap());
  }

  // Centralized Stock Movement Engine
  Future<void> recordStockMovement({
    required String productId,
    required double deltaQty,
    required String type, // Purchase, Sale, Return, Damage, Adjustment
    String reference = '',
    String reason = '',
  }) async {
    final prodIdx = _products.indexWhere((p) => p.id == productId);
    if (prodIdx == -1) return;

    final prod = _products[prodIdx];
    final prevStock = prod.currentStock;
    final newStock = prevStock + deltaQty;
    prod.currentStock = newStock;

    final sm = StockMovement(
      id: 'sm-${DateTime.now().millisecondsSinceEpoch}-${_stockMovements.length}',
      productId: prod.id,
      productName: prod.name,
      type: type,
      quantityDelta: deltaQty,
      previousStock: prevStock,
      newStock: newStock,
      date: DateTime.now(),
      reference: reference,
      reason: reason,
    );

    _stockMovements.insert(0, sm);
    await _db.insert('stock_movements', sm.toMap());
    await _db.update('products', prod.toMap(), 'id', prod.id);
  }

  // POS Cart Management
  double get cartSubtotal => _cart.fold(0.0, (sum, item) => sum + item.total);
  double get cartTotal => (cartSubtotal - _cartDiscount + _cartDeliveryCharge).clamp(0.0, double.infinity);

  void addToCart(Product product, {double quantity = 1.0}) {
    final existingIndex = _cart.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      _cart[existingIndex].quantity += quantity;
    } else {
      _cart.add(CartItem(
        product: product,
        quantity: quantity,
        unitPrice: product.sellingPrice,
      ));
    }
    notifyListeners();
  }

  void updateCartQty(int index, double qty) {
    if (index >= 0 && index < _cart.length) {
      if (qty <= 0) {
        _cart.removeAt(index);
      } else {
        _cart[index].quantity = qty;
      }
      notifyListeners();
    }
  }

  void updateCartPrice(int index, double price) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].unitPrice = price;
      notifyListeners();
    }
  }

  void updateCartDiscount(int index, double discount) {
    if (index >= 0 && index < _cart.length) {
      _cart[index].discount = discount;
      notifyListeners();
    }
  }

  void removeFromCart(int index) {
    if (index >= 0 && index < _cart.length) {
      _cart.removeAt(index);
      notifyListeners();
    }
  }

  void clearCart() {
    _cart.clear();
    _cartDiscount = 0.0;
    _cartDeliveryCharge = 0.0;
    _selectedCustomer = _customers.firstWhere(
      (c) => c.customerType == 'Walk-in',
      orElse: () => Customer(id: 'cust-0', code: 'CUST-000', name: 'Walk-in Customer'),
    );
    notifyListeners();
  }

  void setSelectedCustomer(Customer customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setCartDiscount(double discount) {
    _cartDiscount = discount;
    notifyListeners();
  }

  void setCartDeliveryCharge(double charge) {
    _cartDeliveryCharge = charge;
    notifyListeners();
  }

  // Held Sales
  void holdCurrentCart({String label = ''}) {
    if (_cart.isEmpty) return;
    final held = HeldSale(
      id: 'held-${DateTime.now().millisecondsSinceEpoch}',
      label: label.isNotEmpty ? label : 'Hold #${_heldSales.length + 1}',
      date: DateTime.now(),
      customer: _selectedCustomer,
      cartItems: List.from(_cart),
      discount: _cartDiscount,
      deliveryCharge: _cartDeliveryCharge,
    );
    _heldSales.add(held);
    clearCart();
  }

  void resumeHeldSale(HeldSale held) {
    _cart = List.from(held.cartItems);
    _selectedCustomer = held.customer;
    _cartDiscount = held.discount;
    _cartDeliveryCharge = held.deliveryCharge;
    _heldSales.removeWhere((h) => h.id == held.id);
    notifyListeners();
  }

  void deleteHeldSale(String id) {
    _heldSales.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  // Sales Checkout
  Future<Sale?> checkoutSale({
    required Customer customer,
    required double paidAmount,
    required String primaryPaymentMethod,
    List<SalePaymentSplit>? paymentSplits,
    String notes = '',
  }) async {
    if (_cart.isEmpty) return null;

    final invoiceNo = '${_shopSettings.invoicePrefix}${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final sub = cartSubtotal;
    final disc = _cartDiscount;
    final delCharge = _cartDeliveryCharge;
    final total = cartTotal;

    final actualPaid = paidAmount > total ? total : paidAmount;
    final credit = (total - actualPaid).clamp(0.0, double.infinity);
    final statusStr = credit <= 0 ? 'Paid' : (actualPaid > 0 ? 'Partial' : 'Unpaid/Credit');

    final saleItems = _cart.map((item) {
      return SaleItem(
        productId: item.product.id,
        productCode: item.product.code,
        productName: item.product.name,
        unit: item.product.unit,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        purchasePrice: item.product.purchasePrice,
        discount: item.discount,
        total: item.total,
      );
    }).toList();

    final sale = Sale(
      id: 'sale-${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: invoiceNo,
      date: DateTime.now(),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      subtotal: sub,
      discount: disc,
      tax: 0.0,
      deliveryCharge: delCharge,
      totalAmount: total,
      paidAmount: actualPaid,
      creditAmount: credit,
      paymentStatus: statusStr,
      primaryPaymentMethod: primaryPaymentMethod,
      items: saleItems,
      payments: paymentSplits ?? [SalePaymentSplit(method: primaryPaymentMethod, amount: actualPaid)],
      notes: notes,
    );

    // Update product stocks
    for (var item in saleItems) {
      await recordStockMovement(
        productId: item.productId,
        deltaQty: -item.quantity,
        type: 'Sale',
        reference: invoiceNo,
        reason: 'Sales Invoice $invoiceNo',
      );
    }

    // Update customer credit balance
    if (credit > 0 && customer.customerType != 'Walk-in') {
      final custIdx = _customers.indexWhere((c) => c.id == customer.id);
      if (custIdx >= 0) {
        _customers[custIdx].balance += credit;
        await _db.update('customers', _customers[custIdx].toMap(), 'id', customer.id);
      }
    }

    _sales.insert(0, sale);
    await _db.insert('sales', sale.toMap());
    await addAuditLog('Create Sale', 'Completed sale invoice $invoiceNo for ${customer.name} total $currency $total', reference: invoiceNo);

    // Create delivery if delivery charge > 0 or requested
    if (delCharge > 0) {
      await createDelivery(
        invoiceNo: invoiceNo,
        customer: customer,
        address: customer.address.isNotEmpty ? customer.address : 'Shop Pickup/Delivery',
        deliveryCharge: delCharge,
      );
    }

    clearCart();
    return sale;
  }

  // Quotation Management
  Future<Quotation> createQuotation({
    required Customer customer,
    required List<CartItem> items,
    required double discount,
    required int validDays,
    String notes = '',
  }) async {
    final qNo = 'QT-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final sub = items.fold(0.0, (s, i) => s + i.total);
    final total = (sub - discount).clamp(0.0, double.infinity);

    final qItems = items.map((i) => QuotationItem(
      productId: i.product.id,
      productCode: i.product.code,
      productName: i.product.name,
      unit: i.product.unit,
      quantity: i.quantity,
      unitPrice: i.unitPrice,
      discount: i.discount,
      total: i.total,
    )).toList();

    final q = Quotation(
      id: 'qt-${DateTime.now().millisecondsSinceEpoch}',
      quotationNo: qNo,
      date: DateTime.now(),
      validityDate: DateTime.now().add(Duration(days: validDays)),
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      subtotal: sub,
      discount: discount,
      totalAmount: total,
      items: qItems,
      notes: notes,
    );

    _quotations.insert(0, q);
    await _db.insert('quotations', q.toMap());
    await addAuditLog('Create Quotation', 'Quotation $qNo generated for ${customer.name}', reference: qNo);
    notifyListeners();
    return q;
  }

  void convertQuotationToSale(Quotation q) {
    clearCart();

    final cust = _customers.firstWhere(
      (c) => c.id == q.customerId,
      orElse: () => Customer(id: q.customerId, code: 'CUST-000', name: q.customerName, phone: q.customerPhone),
    );
    setSelectedCustomer(cust);
    setCartDiscount(q.discount);

    for (var qi in q.items) {
      final prod = _products.firstWhere(
        (p) => p.id == qi.productId,
        orElse: () => Product(
          id: qi.productId,
          code: qi.productCode,
          name: qi.productName,
          category: 'General',
          unit: qi.unit,
          purchasePrice: 0,
          sellingPrice: qi.unitPrice,
          currentStock: 100,
        ),
      );
      _cart.add(CartItem(
        product: prod,
        quantity: qi.quantity,
        unitPrice: qi.unitPrice,
        discount: qi.discount,
      ));
    }

    final qIdx = _quotations.indexWhere((item) => item.id == q.id);
    if (qIdx >= 0) {
      final updatedQ = Quotation(
        id: q.id,
        quotationNo: q.quotationNo,
        date: q.date,
        validityDate: q.validityDate,
        customerId: q.customerId,
        customerName: q.customerName,
        customerPhone: q.customerPhone,
        subtotal: q.subtotal,
        discount: q.discount,
        totalAmount: q.totalAmount,
        status: 'Converted',
        notes: q.notes,
        items: q.items,
      );
      _quotations[qIdx] = updatedQ;
      _db.update('quotations', updatedQ.toMap(), 'id', q.id);
    }

    setScreen('pos');
  }

  // Purchases & Supplier Engine
  Future<void> addPurchase({
    required Supplier supplier,
    required String supplierInvoiceNo,
    required DateTime date,
    required List<PurchaseItem> items,
    required double discount,
    required double paidAmount,
    required String paymentMethod,
    String notes = '',
  }) async {
    final purNo = 'PUR-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final sub = items.fold(0.0, (s, i) => s + i.total);
    final total = (sub - discount).clamp(0.0, double.infinity);
    final credit = (total - paidAmount).clamp(0.0, double.infinity);

    final purchase = Purchase(
      id: 'pur-${DateTime.now().millisecondsSinceEpoch}',
      purchaseNo: purNo,
      supplierInvoiceNo: supplierInvoiceNo,
      date: date,
      supplierId: supplier.id,
      supplierName: supplier.name,
      subtotal: sub,
      discount: discount,
      tax: 0.0,
      totalAmount: total,
      paidAmount: paidAmount,
      creditAmount: credit,
      paymentMethod: paymentMethod,
      items: items,
      notes: notes,
    );

    // Stock increase
    for (var item in items) {
      await recordStockMovement(
        productId: item.productId,
        deltaQty: item.quantity,
        type: 'Purchase',
        reference: purNo,
        reason: 'Purchase from ${supplier.name}',
      );
    }

    // Supplier credit update
    if (credit > 0) {
      final supIdx = _suppliers.indexWhere((s) => s.id == supplier.id);
      if (supIdx >= 0) {
        _suppliers[supIdx].balance += credit;
        await _db.update('suppliers', _suppliers[supIdx].toMap(), 'id', supplier.id);
      }
    }

    _purchases.insert(0, purchase);
    await _db.insert('purchases', purchase.toMap());
    await addAuditLog('Create Purchase', 'Purchased goods from ${supplier.name} for $currency $total', reference: purNo);
    notifyListeners();
  }

  // Products CRUD
  Future<void> saveProduct(Product product) async {
    final idx = _products.indexWhere((p) => p.id == product.id);
    if (idx >= 0) {
      _products[idx] = product;
      await _db.update('products', product.toMap(), 'id', product.id);
      await addAuditLog('Update Product', 'Updated product ${product.name} (${product.code})', reference: product.code);
    } else {
      _products.add(product);
      await _db.insert('products', product.toMap());
      await addAuditLog('Add Product', 'Added new product ${product.name} (${product.code})', reference: product.code);
    }
    notifyListeners();
  }

  Future<void> deleteProduct(String id) async {
    final prod = _products.firstWhere((p) => p.id == id, orElse: () => Product(id: '', code: '', name: '', category: '', unit: '', purchasePrice: 0, sellingPrice: 0, currentStock: 0));
    _products.removeWhere((p) => p.id == id);
    await _db.delete('products', 'id', id);
    await addAuditLog('Delete Product', 'Deleted product ${prod.name}', reference: prod.code);
    notifyListeners();
  }

  // Stock Adjustments
  Future<void> adjustStock({
    required String productId,
    required double newPhysicalStock,
    required String reason,
  }) async {
    final prodIdx = _products.indexWhere((p) => p.id == productId);
    if (prodIdx == -1) return;

    final prod = _products[prodIdx];
    final delta = newPhysicalStock - prod.currentStock;
    if (delta == 0) return;

    final type = delta < 0 ? 'Damage' : 'Adjustment';
    await recordStockMovement(
      productId: productId,
      deltaQty: delta,
      type: type,
      reference: 'ADJ-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      reason: reason,
    );

    await addAuditLog('Stock Adjustment', 'Adjusted stock for ${prod.name} by $delta ($reason)', reference: prod.code);
    notifyListeners();
  }

  // Category Management
  Future<void> saveCategory(Category category) async {
    final idx = _categories.indexWhere((c) => c.id == category.id);
    if (idx >= 0) {
      _categories[idx] = category;
      await _db.update('categories', category.toMap(), 'id', category.id);
    } else {
      _categories.add(category);
      await _db.insert('categories', category.toMap());
    }
    notifyListeners();
  }

  // Customers & Payments
  Future<void> saveCustomer(Customer customer) async {
    final idx = _customers.indexWhere((c) => c.id == customer.id);
    if (idx >= 0) {
      _customers[idx] = customer;
      await _db.update('customers', customer.toMap(), 'id', customer.id);
    } else {
      _customers.add(customer);
      await _db.insert('customers', customer.toMap());
    }
    notifyListeners();
  }

  Future<void> recordCustomerPayment({
    required Customer customer,
    required double amount,
    required String paymentMethod,
    String reference = '',
    String notes = '',
  }) async {
    final pay = CustomerPayment(
      id: 'cpay-${DateTime.now().millisecondsSinceEpoch}',
      customerId: customer.id,
      customerName: customer.name,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      date: DateTime.now(),
      notes: notes,
    );

    final custIdx = _customers.indexWhere((c) => c.id == customer.id);
    if (custIdx >= 0) {
      _customers[custIdx].balance = (_customers[custIdx].balance - amount).clamp(0.0, double.infinity);
      await _db.update('customers', _customers[custIdx].toMap(), 'id', customer.id);
    }

    _customerPayments.insert(0, pay);
    await _db.insert('customer_payments', pay.toMap());
    await addAuditLog('Customer Payment', 'Received payment $currency $amount from ${customer.name}', reference: pay.id);
    notifyListeners();
  }

  // Suppliers & Payments
  Future<void> saveSupplier(Supplier supplier) async {
    final idx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (idx >= 0) {
      _suppliers[idx] = supplier;
      await _db.update('suppliers', supplier.toMap(), 'id', supplier.id);
    } else {
      _suppliers.add(supplier);
      await _db.insert('suppliers', supplier.toMap());
    }
    notifyListeners();
  }

  Future<void> recordSupplierPayment({
    required Supplier supplier,
    required double amount,
    required String paymentMethod,
    String reference = '',
    String notes = '',
  }) async {
    final pay = SupplierPayment(
      id: 'spay-${DateTime.now().millisecondsSinceEpoch}',
      supplierId: supplier.id,
      supplierName: supplier.name,
      amount: amount,
      paymentMethod: paymentMethod,
      reference: reference,
      date: DateTime.now(),
      notes: notes,
    );

    final supIdx = _suppliers.indexWhere((s) => s.id == supplier.id);
    if (supIdx >= 0) {
      _suppliers[supIdx].balance = (_suppliers[supIdx].balance - amount).clamp(0.0, double.infinity);
      await _db.update('suppliers', _suppliers[supIdx].toMap(), 'id', supplier.id);
    }

    _supplierPayments.insert(0, pay);
    await _db.insert('supplier_payments', pay.toMap());
    await addAuditLog('Supplier Payment', 'Paid $currency $amount to supplier ${supplier.name}', reference: pay.id);
    notifyListeners();
  }

  // Sales Returns & Refunds
  Future<void> processSalesReturn({
    required String invoiceNo,
    required Customer customer,
    required List<ReturnItem> items,
    required String refundMethod,
    String notes = '',
  }) async {
    final retNo = 'RET-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final total = items.fold(0.0, (s, i) => s + i.total);

    final salesReturn = SalesReturn(
      id: 'ret-${DateTime.now().millisecondsSinceEpoch}',
      returnNo: retNo,
      invoiceNo: invoiceNo,
      date: DateTime.now(),
      customerId: customer.id,
      customerName: customer.name,
      totalAmount: total,
      refundMethod: refundMethod,
      items: items,
      notes: notes,
    );

    // Process Stock Movement
    for (var item in items) {
      if (!item.isDamaged) {
        await recordStockMovement(
          productId: item.productId,
          deltaQty: item.quantity,
          type: 'Return',
          reference: retNo,
          reason: 'Return: ${item.reason}',
        );
      } else {
        await recordStockMovement(
          productId: item.productId,
          deltaQty: 0.0,
          type: 'Damage',
          reference: retNo,
          reason: 'Damaged item return: ${item.reason}',
        );
      }
    }

    // Process Refund Record
    final refund = RefundRecord(
      id: 'ref-${DateTime.now().millisecondsSinceEpoch}',
      returnNo: retNo,
      invoiceNo: invoiceNo,
      customerName: customer.name,
      amount: total,
      refundMethod: refundMethod,
      date: DateTime.now(),
      notes: notes,
    );

    if (refundMethod == 'Customer Credit' && customer.customerType != 'Walk-in') {
      final custIdx = _customers.indexWhere((c) => c.id == customer.id);
      if (custIdx >= 0) {
        _customers[custIdx].balance = (_customers[custIdx].balance - total).clamp(0.0, double.infinity);
        await _db.update('customers', _customers[custIdx].toMap(), 'id', customer.id);
      }
    }

    _salesReturns.insert(0, salesReturn);
    _refunds.insert(0, refund);

    await _db.insert('sales_returns', salesReturn.toMap());
    await _db.insert('refund_records', refund.toMap());
    await addAuditLog('Sales Return', 'Processed return $retNo for invoice $invoiceNo total $currency $total', reference: retNo);

    notifyListeners();
  }

  // Warranty Management
  Future<void> createWarrantyClaim({
    required String invoiceNo,
    required Customer customer,
    required Product product,
    required String serialNumber,
    required DateTime purchaseDate,
    required String issue,
    String notes = '',
  }) async {
    final claimNo = 'WC-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final claim = WarrantyClaim(
      id: 'wc-${DateTime.now().millisecondsSinceEpoch}',
      claimNo: claimNo,
      invoiceNo: invoiceNo,
      customerId: customer.id,
      customerName: customer.name,
      customerPhone: customer.phone,
      productId: product.id,
      productName: product.name,
      serialNumber: serialNumber,
      purchaseDate: purchaseDate,
      dateReceived: DateTime.now(),
      issueDescription: issue,
      status: 'Pending',
      notes: notes,
    );

    _warrantyClaims.insert(0, claim);
    await _db.insert('warranty_claims', claim.toMap());
    await addAuditLog('Warranty Claim', 'Logged warranty claim $claimNo for product ${product.name}', reference: claimNo);
    notifyListeners();
  }

  Future<void> updateWarrantyStatus(String claimId, String newStatus, {String notes = ''}) async {
    final idx = _warrantyClaims.indexWhere((w) => w.id == claimId);
    if (idx >= 0) {
      final claim = _warrantyClaims[idx];
      claim.status = newStatus;
      await _db.update('warranty_claims', claim.toMap(), 'id', claimId);
      await addAuditLog('Warranty Update', 'Warranty claim ${claim.claimNo} updated to status $newStatus', reference: claim.claimNo);
      notifyListeners();
    }
  }

  // Delivery Management
  Future<Delivery> createDelivery({
    required String invoiceNo,
    required Customer customer,
    required String address,
    String phone = '',
    String driverName = '',
    String vehicleNo = '',
    double deliveryCharge = 0.0,
    String notes = '',
  }) async {
    final delNo = 'DEL-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final del = Delivery(
      id: 'del-${DateTime.now().millisecondsSinceEpoch}',
      deliveryNo: delNo,
      invoiceNo: invoiceNo,
      customerId: customer.id,
      customerName: customer.name,
      phone: phone.isNotEmpty ? phone : customer.phone,
      address: address,
      deliveryDate: DateTime.now(),
      expectedDate: DateTime.now().add(const Duration(days: 1)),
      driverName: driverName,
      vehicleNo: vehicleNo,
      deliveryCharge: deliveryCharge,
      status: 'Pending',
      notes: notes,
    );

    _deliveries.insert(0, del);
    await _db.insert('deliveries', del.toMap());
    await addAuditLog('Create Delivery', 'Created delivery note $delNo for invoice $invoiceNo', reference: delNo);
    notifyListeners();
    return del;
  }

  Future<void> updateDeliveryStatus(String id, String newStatus, {String driverName = '', String vehicleNo = '', String receivedBy = ''}) async {
    final idx = _deliveries.indexWhere((d) => d.id == id);
    if (idx >= 0) {
      final del = _deliveries[idx];
      del.status = newStatus;
      if (newStatus == 'Delivered') {
        _deliveries[idx] = Delivery(
          id: del.id,
          deliveryNo: del.deliveryNo,
          invoiceNo: del.invoiceNo,
          customerId: del.customerId,
          customerName: del.customerName,
          phone: del.phone,
          address: del.address,
          deliveryDate: del.deliveryDate,
          expectedDate: del.expectedDate,
          driverName: driverName.isNotEmpty ? driverName : del.driverName,
          vehicleNo: vehicleNo.isNotEmpty ? vehicleNo : del.vehicleNo,
          deliveryCharge: del.deliveryCharge,
          status: newStatus,
          notes: del.notes,
          deliveredDate: DateTime.now(),
          receivedBy: receivedBy,
        );
      }
      await _db.update('deliveries', _deliveries[idx].toMap(), 'id', id);
      await addAuditLog('Delivery Update', 'Delivery ${del.deliveryNo} updated to $newStatus', reference: del.deliveryNo);
      notifyListeners();
    }
  }

  // Expense Management
  Future<void> addExpense({
    required String categoryName,
    required String description,
    required double amount,
    required String paymentMethod,
    String reference = '',
    String notes = '',
  }) async {
    final exp = Expense(
      id: 'exp-${DateTime.now().millisecondsSinceEpoch}',
      categoryName: categoryName,
      description: description,
      amount: amount,
      date: DateTime.now(),
      paymentMethod: paymentMethod,
      reference: reference,
      notes: notes,
    );

    _expenses.insert(0, exp);
    await _db.insert('expenses', exp.toMap());
    await addAuditLog('Add Expense', 'Recorded expense $categoryName of $currency $amount ($description)', reference: exp.id);
    notifyListeners();
  }

  Future<void> deleteExpense(String id) async {
    final exp = _expenses.firstWhere((e) => e.id == id, orElse: () => Expense(id: '', categoryName: '', description: '', amount: 0, date: DateTime.now()));
    _expenses.removeWhere((e) => e.id == id);
    await _db.delete('expenses', 'id', id);
    await addAuditLog('Delete Expense', 'Deleted expense ${exp.categoryName} $currency ${exp.amount}', reference: id);
    notifyListeners();
  }

  // Day Closing Reconciliation
  Future<DayClosing> performDayClosing({
    required String cashierName,
    required double openingCash,
    required double actualCash,
    String notes = '',
  }) async {
    final today = DateTime.now();
    final todaySales = _sales.where((s) =>
        s.date.year == today.year && s.date.month == today.month && s.date.day == today.day && s.status != 'Cancelled').toList();

    double cashSales = 0.0;
    for (var s in todaySales) {
      for (var p in s.payments) {
        if (p.method == 'Cash') cashSales += p.amount;
      }
    }

    final todayRefunds = _refunds.where((r) =>
        r.date.year == today.year && r.date.month == today.month && r.date.day == today.day && r.refundMethod == 'Cash').toList();
    double cashRefunds = todayRefunds.fold(0.0, (sum, r) => sum + r.amount);

    final todayExp = _expenses.where((e) =>
        e.date.year == today.year && e.date.month == today.month && e.date.day == today.day && e.paymentMethod == 'Cash').toList();
    double cashExpenses = todayExp.fold(0.0, (sum, e) => sum + e.amount);

    final expectedCash = openingCash + cashSales - cashRefunds - cashExpenses;
    final diff = actualCash - expectedCash;

    final dc = DayClosing(
      id: 'dc-${DateTime.now().millisecondsSinceEpoch}',
      date: today,
      cashierName: cashierName,
      openingCash: openingCash,
      cashSales: cashSales,
      cashRefunds: cashRefunds,
      expenses: cashExpenses,
      expectedCash: expectedCash,
      actualCash: actualCash,
      difference: diff,
      notes: notes,
    );

    _dayClosings.insert(0, dc);
    await _db.insert('day_closings', dc.toMap());
    await addAuditLog('Day Closing', 'Performed cashier cash closing. Expected $currency $expectedCash, Actual $currency $actualCash (Diff: $currency $diff)', reference: dc.id);

    notifyListeners();
    return dc;
  }

  // Settings & Users
  Future<void> updateSettings(ShopSettings settings) async {
    _shopSettings = settings;
    await _db.update('settings', {'id': 1, ...settings.toMap()}, 'id', '1');
    await addAuditLog('Update Settings', 'Updated shop profile settings');
    notifyListeners();
  }

  Future<void> saveUser(User user) async {
    final idx = _users.indexWhere((u) => u.id == user.id);
    if (idx >= 0) {
      _users[idx] = user;
      await _db.update('users', user.toMap(), 'id', user.id);
    } else {
      _users.add(user);
      await _db.insert('users', user.toMap());
    }
    notifyListeners();
  }

  // Low Stock & KPI Summary Getters
  List<Product> get lowStockProducts => _products.where((p) => p.currentStock <= p.reorderLevel).toList();
  List<Delivery> get pendingDeliveries => _deliveries.where((d) => d.status == 'Pending' || d.status == 'Scheduled' || d.status == 'Out for Delivery').toList();
  List<WarrantyClaim> get activeWarrantyClaims => _warrantyClaims.where((w) => w.status != 'Completed' && w.status != 'Rejected').toList();

  double get todaySalesTotal {
    final today = DateTime.now();
    return _sales
        .where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day && s.status != 'Cancelled')
        .fold(0.0, (sum, s) => sum + s.totalAmount);
  }

  double get todayPurchasesTotal {
    final today = DateTime.now();
    return _purchases
        .where((p) => p.date.year == today.year && p.date.month == today.month && p.date.day == today.day)
        .fold(0.0, (sum, p) => sum + p.totalAmount);
  }

  double get todayProfitTotal {
    final today = DateTime.now();
    final todaySalesList = _sales.where((s) => s.date.year == today.year && s.date.month == today.month && s.date.day == today.day && s.status != 'Cancelled');

    double grossProfit = 0.0;
    for (var s in todaySalesList) {
      for (var item in s.items) {
        final cost = item.purchasePrice * item.quantity;
        grossProfit += (item.total - cost);
      }
    }

    final todayExp = _expenses
        .where((e) => e.date.year == today.year && e.date.month == today.month && e.date.day == today.day)
        .fold(0.0, (sum, e) => sum + e.amount);

    return grossProfit - todayExp;
  }

  double get totalCustomerOutstanding => _customers.fold(0.0, (sum, c) => sum + c.balance);
  double get totalSupplierOutstanding => _suppliers.fold(0.0, (sum, s) => sum + s.balance);
}
