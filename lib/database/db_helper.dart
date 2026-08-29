import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../models/audit_log.dart';
import 'seed_data.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path;
    if (kIsWeb) {
      path = 'iron_stock_hardware.db';
    } else if (Platform.environment.containsKey('FLUTTER_TEST')) {
      path = inMemoryDatabasePath;
    } else {
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        path = p.join(docsDir.path, 'iron_stock_hardware.db');
      } catch (_) {
        path = inMemoryDatabasePath;
      }
    }

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Categories
    await db.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT
      )
    ''');

    // Products
    await db.execute('''
      CREATE TABLE products (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        brand TEXT,
        description TEXT,
        unit TEXT NOT NULL,
        purchasePrice REAL NOT NULL,
        sellingPrice REAL NOT NULL,
        wholesalePrice REAL,
        currentStock REAL NOT NULL,
        minStock REAL,
        reorderLevel REAL,
        supplierId TEXT,
        supplierName TEXT,
        rackLocation TEXT,
        warrantyMonths INTEGER,
        taxPercent REAL,
        discountAllowed INTEGER,
        status TEXT
      )
    ''');

    // Customers
    await db.execute('''
      CREATE TABLE customers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        customerType TEXT,
        creditLimit REAL,
        balance REAL,
        openingBalance REAL,
        notes TEXT
      )
    ''');

    // Customer Payments
    await db.execute('''
      CREATE TABLE customer_payments (
        id TEXT PRIMARY KEY,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        reference TEXT,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Suppliers
    await db.execute('''
      CREATE TABLE suppliers (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        company TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        taxVatNo TEXT,
        openingBalance REAL,
        balance REAL,
        creditLimit REAL,
        notes TEXT
      )
    ''');

    // Supplier Payments
    await db.execute('''
      CREATE TABLE supplier_payments (
        id TEXT PRIMARY KEY,
        supplierId TEXT NOT NULL,
        supplierName TEXT NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        reference TEXT,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Sales
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        invoiceNo TEXT NOT NULL,
        date TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT,
        subtotal REAL NOT NULL,
        discount REAL,
        tax REAL,
        deliveryCharge REAL,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        creditAmount REAL NOT NULL,
        paymentStatus TEXT NOT NULL,
        primaryPaymentMethod TEXT NOT NULL,
        itemsJson TEXT NOT NULL,
        paymentsJson TEXT,
        notes TEXT,
        status TEXT
      )
    ''');

    // Purchases
    await db.execute('''
      CREATE TABLE purchases (
        id TEXT PRIMARY KEY,
        purchaseNo TEXT NOT NULL,
        supplierInvoiceNo TEXT,
        date TEXT NOT NULL,
        supplierId TEXT NOT NULL,
        supplierName TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount REAL,
        tax REAL,
        totalAmount REAL NOT NULL,
        paidAmount REAL NOT NULL,
        creditAmount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        itemsJson TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Quotations
    await db.execute('''
      CREATE TABLE quotations (
        id TEXT PRIMARY KEY,
        quotationNo TEXT NOT NULL,
        date TEXT NOT NULL,
        validityDate TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT,
        subtotal REAL NOT NULL,
        discount REAL,
        totalAmount REAL NOT NULL,
        status TEXT NOT NULL,
        notes TEXT,
        itemsJson TEXT NOT NULL
      )
    ''');

    // Sales Returns
    await db.execute('''
      CREATE TABLE sales_returns (
        id TEXT PRIMARY KEY,
        returnNo TEXT NOT NULL,
        invoiceNo TEXT NOT NULL,
        date TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        refundMethod TEXT NOT NULL,
        notes TEXT,
        itemsJson TEXT NOT NULL
      )
    ''');

    // Refund Records
    await db.execute('''
      CREATE TABLE refund_records (
        id TEXT PRIMARY KEY,
        returnNo TEXT NOT NULL,
        invoiceNo TEXT NOT NULL,
        customerName TEXT NOT NULL,
        amount REAL NOT NULL,
        refundMethod TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Warranty Claims
    await db.execute('''
      CREATE TABLE warranty_claims (
        id TEXT PRIMARY KEY,
        claimNo TEXT NOT NULL,
        invoiceNo TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        customerPhone TEXT,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        serialNumber TEXT NOT NULL,
        purchaseDate TEXT NOT NULL,
        dateReceived TEXT NOT NULL,
        issueDescription TEXT NOT NULL,
        status TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // Deliveries
    await db.execute('''
      CREATE TABLE deliveries (
        id TEXT PRIMARY KEY,
        deliveryNo TEXT NOT NULL,
        invoiceNo TEXT NOT NULL,
        customerId TEXT NOT NULL,
        customerName TEXT NOT NULL,
        phone TEXT,
        address TEXT NOT NULL,
        deliveryDate TEXT NOT NULL,
        expectedDate TEXT NOT NULL,
        driverName TEXT,
        vehicleNo TEXT,
        deliveryCharge REAL,
        status TEXT NOT NULL,
        notes TEXT,
        deliveredDate TEXT,
        receivedBy TEXT
      )
    ''');

    // Expense Categories
    await db.execute('''
      CREATE TABLE expense_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL
      )
    ''');

    // Expenses
    await db.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        categoryName TEXT NOT NULL,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        paymentMethod TEXT,
        reference TEXT,
        notes TEXT
      )
    ''');

    // Stock Movements
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        type TEXT NOT NULL,
        quantityDelta REAL NOT NULL,
        previousStock REAL NOT NULL,
        newStock REAL NOT NULL,
        date TEXT NOT NULL,
        reference TEXT,
        reason TEXT
      )
    ''');

    // Day Closings
    await db.execute('''
      CREATE TABLE day_closings (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        cashierName TEXT NOT NULL,
        openingCash REAL NOT NULL,
        cashSales REAL NOT NULL,
        cashRefunds REAL NOT NULL,
        expenses REAL NOT NULL,
        expectedCash REAL NOT NULL,
        actualCash REAL NOT NULL,
        difference REAL NOT NULL,
        notes TEXT
      )
    ''');

    // Users
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        name TEXT NOT NULL,
        role TEXT NOT NULL,
        pinOrPassword TEXT NOT NULL,
        permissions TEXT,
        isActive INTEGER NOT NULL
      )
    ''');

    // Audit Logs
    await db.execute('''
      CREATE TABLE audit_logs (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL,
        action TEXT NOT NULL,
        details TEXT NOT NULL,
        date TEXT NOT NULL,
        reference TEXT
      )
    ''');

    // Shop Settings
    await db.execute('''
      CREATE TABLE settings (
        id INTEGER PRIMARY KEY DEFAULT 1,
        shopName TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        logoPath TEXT,
        currency TEXT,
        invoicePrefix TEXT,
        receiptPrefix TEXT,
        lowStockThreshold REAL,
        autoBackupEnabled INTEGER,
        backupDirectory TEXT
      )
    ''');

    // Seed Initial Data
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    for (var cat in SeedData.defaultCategories) {
      await db.insert('categories', cat.toMap());
    }
    for (var prod in SeedData.defaultProducts) {
      await db.insert('products', prod.toMap());
    }
    for (var cust in SeedData.defaultCustomers) {
      await db.insert('customers', cust.toMap());
    }
    for (var sup in SeedData.defaultSuppliers) {
      await db.insert('suppliers', sup.toMap());
    }
    for (var user in SeedData.defaultUsers) {
      await db.insert('users', user.toMap());
    }
    for (var expCat in SeedData.defaultExpenseCategories) {
      await db.insert('expense_categories', expCat.toMap());
    }
    await db.insert('settings', {'id': 1, ...SeedData.defaultSettings.toMap()});

    // Sample Audit Log
    await db.insert('audit_logs', AuditLog(
      id: 'log-1',
      username: 'admin',
      action: 'System Initialized',
      details: 'Hardware Shop Management System database created and seeded.',
      date: DateTime.now(),
    ).toMap());
  }

  // Generic Helpers
  Future<List<Map<String, dynamic>>> queryAll(String table) async {
    final db = await instance.database;
    return await db.query(table);
  }

  Future<int> insert(String table, Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert(table, row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<int> update(String table, Map<String, dynamic> row, String idColumn, String idValue) async {
    final db = await instance.database;
    return await db.update(table, row, where: '$idColumn = ?', whereArgs: [idValue]);
  }

  Future<int> delete(String table, String idColumn, String idValue) async {
    final db = await instance.database;
    return await db.delete(table, where: '$idColumn = ?', whereArgs: [idValue]);
  }

  Future<void> clearAllData() async {
    final db = await instance.database;
    final tables = [
      'categories', 'products', 'customers', 'customer_payments',
      'suppliers', 'supplier_payments', 'sales', 'purchases',
      'quotations', 'sales_returns', 'refund_records', 'warranty_claims',
      'deliveries', 'expense_categories', 'expenses', 'stock_movements',
      'day_closings', 'users', 'audit_logs', 'settings'
    ];
    for (var table in tables) {
      await db.delete(table);
    }
    await _seedDatabase(db);
  }
}
