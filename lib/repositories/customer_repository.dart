import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../models/customer.dart';

class CustomerRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Customer>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(DbConstants.customers, orderBy: 'name ASC');
    return rows.map(Customer.fromMap).toList();
  }

  Future<int> insert(Customer c) async {
    final db = await _db.database;
    return db.insert(DbConstants.customers, c.toMap()..remove('id'));
  }

  Future<int> update(Customer c) async {
    final db = await _db.database;
    return db.update(DbConstants.customers, c.toMap()..remove('id'), where: 'id = ?', whereArgs: [c.id]);
  }

  Future<int> delete(int id) async {
    final db = await _db.database;
    return db.delete(DbConstants.customers, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> updateBalance(int id, double delta) async {
    final db = await _db.database;
    await db.rawUpdate(
      'UPDATE ${DbConstants.customers} SET current_balance = current_balance + ? WHERE id = ?',
      [delta, id],
    );
  }
}
