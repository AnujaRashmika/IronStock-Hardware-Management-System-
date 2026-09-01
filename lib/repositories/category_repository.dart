import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../models/category.dart';

class CategoryRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Category>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(DbConstants.categories, orderBy: 'name ASC');
    return rows.map(Category.fromMap).toList();
  }

  Future<int> insert(Category c) async {
    final db = await _db.database;
    return db.insert(DbConstants.categories, c.toMap()..remove('id'));
  }

  Future<int> update(Category c) async {
    final db = await _db.database;
    return db.update(DbConstants.categories, c.toMap()..remove('id'), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(DbConstants.categories, where: 'id = ?', whereArgs: [id]);
  }
}
