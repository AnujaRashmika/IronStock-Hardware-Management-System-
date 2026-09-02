import '../core/database/database_helper.dart';
import '../models/note.dart';

class NoteRepository {
  Future<List<Note>> getAll() async {
    final db = await DatabaseHelper.instance.database;
    try {
      final rows = await db.query('notes', orderBy: 'created_at DESC');
      return rows.map(Note.fromMap).toList();
    } catch (_) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS notes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          content TEXT,
          created_at TEXT NOT NULL,
          updated_at TEXT
        )
      ''');
      return [];
    }
  }

  Future<int> insert(Note n) async {
    final db = await DatabaseHelper.instance.database;
    return db.insert('notes', n.toMap()..remove('id'));
  }

  Future<void> update(Note n) async {
    final db = await DatabaseHelper.instance.database;
    await db.update('notes', n.toMap()..remove('id'), where: 'id = ?', whereArgs: [n.id]);
  }

  Future<void> delete(int id) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('notes', where: 'id = ?', whereArgs: [id]);
  }
}
