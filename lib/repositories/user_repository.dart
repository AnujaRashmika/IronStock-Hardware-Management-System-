import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../models/user.dart';

class UserRepository {
  final _db = DatabaseHelper.instance;

  Future<User?> login(String username, String password) async {
    final db = await _db.database;
    final rows = await db.query(
      DbConstants.users,
      where: 'username = ? AND password = ? AND is_active = 1',
      whereArgs: [username, password],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return User.fromMap(rows.first);
  }

  Future<List<User>> getAll() async {
    final db = await _db.database;
    final rows = await db.query(DbConstants.users, orderBy: 'full_name ASC');
    return rows.map(User.fromMap).toList();
  }

  Future<int> insert(User u) async {
    final db = await _db.database;
    return db.insert(DbConstants.users, u.toMap()..remove('id'));
  }

  Future<int> update(User u) async {
    final db = await _db.database;
    return db.update(DbConstants.users, u.toMap()..remove('id'), where: 'id = ?', whereArgs: [u.id]);
  }
}
