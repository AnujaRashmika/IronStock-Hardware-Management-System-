import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../models/product.dart';

class ProductRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Product>> getAll({bool activeOnly = false}) async {
    final db = await _db.database;
    final rows = await db.query(
      DbConstants.products,
      where: activeOnly ? 'is_active = 1' : null,
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<List<Product>> search(String q) async {
    final db = await _db.database;
    final rows = await db.query(
      DbConstants.products,
      where: 'name LIKE ? OR sku LIKE ? OR barcode LIKE ? OR brand LIKE ?',
      whereArgs: ['%$q%', '%$q%', '%$q%', '%$q%'],
      orderBy: 'name ASC',
    );
    return rows.map(Product.fromMap).toList();
  }

  Future<Product?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(DbConstants.products, where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first);
  }

  Future<int> insert(Product p) async {
    final db = await _db.database;
    return db.insert(DbConstants.products, p.toMap()..remove('id'));
  }

  Future<int> update(Product p) async {
    final db = await _db.database;
    return db.update(DbConstants.products, p.toMap()..remove('id'), where: 'id = ?', whereArgs: [p.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.update(DbConstants.products, {'is_active': 0}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> hardDelete(int id) async {
    final db = await _db.database;
    return db.delete(DbConstants.products, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Product>> lowStock() async {
    final db = await _db.database;
    final rows = await db.rawQuery('''
      SELECT * FROM ${DbConstants.products}
      WHERE is_active = 1 AND stock_quantity <= reorder_level
      ORDER BY stock_quantity ASC
    ''');
    return rows.map(Product.fromMap).toList();
  }
}
