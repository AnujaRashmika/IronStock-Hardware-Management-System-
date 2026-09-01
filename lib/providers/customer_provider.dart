import 'package:flutter/material.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';
import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

class CustomerProvider extends ChangeNotifier {
  final _repo = CustomerRepository();
  List<Customer> _customers = [];
  List<Customer> _all = [];
  bool isLoading = false;
  bool isLoadingOrders = false;
  String searchQuery = '';
  List<Map<String, dynamic>> selectedCustomerOrders = [];

  List<Customer> get customers => _customers;

  Future<void> loadCustomers() async {
    isLoading = true;
    notifyListeners();
    try {
      _all = await _repo.getAll();
      _applySearch();
    } catch (_) {}
    isLoading = false;
    notifyListeners();
  }

  void searchCustomers(String q) {
    searchQuery = q;
    _applySearch();
    notifyListeners();
  }

  void _applySearch() {
    if (searchQuery.trim().isEmpty) {
      _customers = List.from(_all);
    } else {
      final lower = searchQuery.toLowerCase();
      _customers = _all.where((c) {
        return c.name.toLowerCase().contains(lower) ||
            (c.phone ?? '').contains(lower);
      }).toList();
    }
  }

  Future<bool> addCustomer(Customer c) async {
    try {
      await _repo.insert(c);
      await loadCustomers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> updateCustomer(Customer c) async {
    try {
      await _repo.update(c);
      await loadCustomers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      await _repo.delete(id);
      await loadCustomers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadCustomerOrders(int customerId) async {
    isLoadingOrders = true;
    notifyListeners();
    try {
      final db = await DatabaseHelper.instance.database;
      selectedCustomerOrders = await db.query(
        DbConstants.sales,
        where: 'customer_id = ?',
        whereArgs: [customerId],
        orderBy: 'created_at DESC',
      );
    } catch (_) {
      selectedCustomerOrders = [];
    }
    isLoadingOrders = false;
    notifyListeners();
  }
}
