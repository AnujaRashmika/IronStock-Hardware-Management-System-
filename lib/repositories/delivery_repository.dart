import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

class DeliveryRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAll({String? status}) async {
    final db = await _db.database;
    if (status != null) {
      return db.query(DbConstants.deliveries,
          where: 'status = ?', whereArgs: [status], orderBy: 'created_at DESC');
    }
    return db.query(DbConstants.deliveries, orderBy: 'created_at DESC');
  }

  Future<void> updateStatus(int id, String status,
      {String? receivedBy, String? notes}) async {
    final db = await _db.database;
    final map = <String, dynamic>{'status': status};
    if (status == 'Delivered') {
      map['delivered_at'] = DateTime.now().toIso8601String();
      map['received_by'] = receivedBy;
    }
    if (notes != null) map['notes'] = notes;
    await db.update(DbConstants.deliveries, map, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, int>> counts() async {
    final db = await _db.database;
    final all = await db.query(DbConstants.deliveries);
    final map = <String, int>{};
    for (final r in all) {
      final s = r['status'] as String? ?? 'Pending';
      map[s] = (map[s] ?? 0) + 1;
    }
    return map;
  }
}
