import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/db_constants.dart';
import '../constants/app_constants.dart';

class DatabaseHelper {
  DatabaseHelper._();
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, DbConstants.databaseName);
    return openDatabase(
      path,
      version: DbConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE ${DbConstants.users} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT NOT NULL UNIQUE,
        password TEXT NOT NULL,
        full_name TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'cashier',
        is_active INTEGER NOT NULL DEFAULT 1,
        permissions TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.categories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        description TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.products} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sku TEXT,
        name TEXT NOT NULL,
        category_id INTEGER,
        brand TEXT,
        description TEXT,
        unit TEXT NOT NULL DEFAULT 'Piece',
        purchase_price REAL NOT NULL DEFAULT 0,
        selling_price REAL NOT NULL DEFAULT 0,
        wholesale_price REAL NOT NULL DEFAULT 0,
        stock_quantity REAL NOT NULL DEFAULT 0,
        min_stock REAL NOT NULL DEFAULT 5,
        reorder_level REAL NOT NULL DEFAULT 10,
        supplier_id INTEGER,
        rack_location TEXT,
        warranty_months INTEGER DEFAULT 0,
        tax_rate REAL DEFAULT 0,
        barcode TEXT,
        is_active INTEGER NOT NULL DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.customers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        customer_type TEXT DEFAULT 'Regular',
        credit_limit REAL DEFAULT 0,
        opening_balance REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.suppliers} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        code TEXT,
        name TEXT NOT NULL,
        company TEXT,
        phone TEXT,
        email TEXT,
        address TEXT,
        tax_no TEXT,
        credit_limit REAL DEFAULT 0,
        current_balance REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.sales} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_name TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL DEFAULT 0,
        delivery_charge REAL NOT NULL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid_amount REAL NOT NULL DEFAULT 0,
        balance REAL NOT NULL DEFAULT 0,
        payment_status TEXT DEFAULT 'paid',
        sale_status TEXT DEFAULT 'completed',
        is_credit INTEGER DEFAULT 0,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL,
        updated_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.saleItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${DbConstants.sales}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.salePayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT NOT NULL,
        reference TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES ${DbConstants.sales}(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.purchases} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_no TEXT NOT NULL,
        supplier_id INTEGER,
        supplier_name TEXT,
        subtotal REAL NOT NULL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL NOT NULL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        balance REAL DEFAULT 0,
        payment_status TEXT DEFAULT 'paid',
        notes TEXT,
        purchase_date TEXT NOT NULL,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.purchaseItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        purchase_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        unit TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        FOREIGN KEY (purchase_id) REFERENCES ${DbConstants.purchases}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.quotations} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quote_no TEXT NOT NULL UNIQUE,
        customer_id INTEGER,
        customer_name TEXT,
        subtotal REAL DEFAULT 0,
        discount REAL DEFAULT 0,
        tax REAL DEFAULT 0,
        total REAL DEFAULT 0,
        validity_days INTEGER DEFAULT 7,
        notes TEXT,
        status TEXT DEFAULT 'draft',
        created_at TEXT NOT NULL,
        converted_sale_id INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.quotationItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quotation_id INTEGER NOT NULL,
        product_id INTEGER,
        product_name TEXT NOT NULL,
        unit TEXT,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        discount REAL DEFAULT 0,
        total REAL NOT NULL,
        FOREIGN KEY (quotation_id) REFERENCES ${DbConstants.quotations}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.returns} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_no TEXT NOT NULL UNIQUE,
        sale_id INTEGER,
        invoice_no TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        return_type TEXT DEFAULT 'sales_return',
        reason TEXT,
        subtotal REAL DEFAULT 0,
        total REAL DEFAULT 0,
        restock INTEGER DEFAULT 1,
        status TEXT DEFAULT 'completed',
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.returnItems} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        return_id INTEGER NOT NULL,
        product_id INTEGER NOT NULL,
        product_name TEXT NOT NULL,
        quantity REAL NOT NULL,
        unit_price REAL NOT NULL,
        total REAL NOT NULL,
        is_damaged INTEGER DEFAULT 0,
        FOREIGN KEY (return_id) REFERENCES ${DbConstants.returns}(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.refunds} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        refund_no TEXT NOT NULL UNIQUE,
        return_id INTEGER,
        sale_id INTEGER,
        amount REAL NOT NULL,
        refund_method TEXT NOT NULL,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.warranties} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        warranty_no TEXT NOT NULL UNIQUE,
        sale_id INTEGER,
        invoice_no TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        product_id INTEGER,
        product_name TEXT,
        serial_number TEXT,
        purchase_date TEXT,
        warranty_start TEXT,
        warranty_end TEXT,
        months INTEGER DEFAULT 0,
        status TEXT DEFAULT 'active',
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.warrantyClaims} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        claim_no TEXT NOT NULL UNIQUE,
        warranty_id INTEGER,
        customer_name TEXT,
        product_name TEXT,
        serial_number TEXT,
        issue TEXT,
        status TEXT DEFAULT 'Pending',
        date_received TEXT,
        notes TEXT,
        resolved_at TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.deliveries} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        delivery_no TEXT NOT NULL UNIQUE,
        sale_id INTEGER,
        invoice_no TEXT,
        customer_id INTEGER,
        customer_name TEXT,
        address TEXT,
        phone TEXT,
        delivery_date TEXT,
        expected_date TEXT,
        driver TEXT,
        vehicle TEXT,
        delivery_charge REAL DEFAULT 0,
        status TEXT DEFAULT 'Pending',
        delivered_at TEXT,
        received_by TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.expenseCategories} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.expenses} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        category_name TEXT,
        title TEXT NOT NULL,
        description TEXT,
        amount REAL NOT NULL,
        payment_method TEXT,
        reference TEXT,
        expense_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.stockMovements} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        product_name TEXT,
        type TEXT NOT NULL,
        quantity REAL NOT NULL,
        reference TEXT,
        notes TEXT,
        created_by INTEGER,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.customerPayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.supplierPayments} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        supplier_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT,
        reference TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.settings} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        key TEXT NOT NULL UNIQUE,
        value TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.activityLog} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER,
        username TEXT,
        action TEXT NOT NULL,
        entity_type TEXT,
        entity_id INTEGER,
        details TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE ${DbConstants.cashClosings} (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        opening_cash REAL DEFAULT 0,
        cash_sales REAL DEFAULT 0,
        cash_refunds REAL DEFAULT 0,
        expenses REAL DEFAULT 0,
        expected_cash REAL DEFAULT 0,
        actual_cash REAL DEFAULT 0,
        difference REAL DEFAULT 0,
        notes TEXT,
        closed_by INTEGER,
        closing_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    // Default admin only — no sample products
    await db.insert(DbConstants.users, {
      'username': AppConstants.defaultAdminUsername,
      'password': AppConstants.defaultAdminPassword,
      'full_name': 'Administrator',
      'role': 'admin',
      'is_active': 1,
      'permissions': 'all',
      'created_at': DateTime.now().toIso8601String(),
    });

    // Default expense categories
    final now = DateTime.now().toIso8601String();
    for (final name in [
      'Transport', 'Electricity', 'Water', 'Rent', 'Salary',
      'Fuel', 'Maintenance', 'Delivery', 'Telephone', 'Stationery', 'Other'
    ]) {
      await db.insert(DbConstants.expenseCategories, {
        'name': name,
        'created_at': now,
      });
    }

    // Default settings
    final defaults = {
      'shop_name': 'My Hardware Store',
      'shop_address': '',
      'shop_phone': '',
      'currency': 'LKR',
      'tax_rate': '0',
      'invoice_prefix': 'INV-',
      'receipt_footer': 'Thank you for shopping with us!',
    };
    for (final e in defaults.entries) {
      await db.insert(DbConstants.settings, {'key': e.key, 'value': e.value});
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Future migrations
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _db = null;
  }
}
