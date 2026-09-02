import '../database/database_helper.dart';
import '../constants/db_constants.dart';

class ActivityLogger {
  ActivityLogger._();

  static Future<void> log({
    required String action,
    String? entityType,
    int? entityId,
    String? details,
    String? username,
  }) async {
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert(DbConstants.activityLog, {
        'action': action,
        'entity_type': entityType,
        'entity_id': entityId,
        'details': details,
        'username': username,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  static Future<List<Map<String, dynamic>>> query({
    String period = 'all',
    String category = 'all',
    int limit = 500,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    String? from;
    switch (period) {
      case 'today':
        from = DateTime(now.year, now.month, now.day).toIso8601String();
        break;
      case 'yesterday':
        final y = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
        final end = DateTime(now.year, now.month, now.day).toIso8601String();
        final start = y.toIso8601String();
        var where = 'created_at >= ? AND created_at < ?';
        final args = <Object>[start, end];
        if (category != 'all') {
          where += ' AND (${_categoryClause(category)})';
        }
        return db.query(DbConstants.activityLog, where: where, whereArgs: args, orderBy: 'created_at DESC', limit: limit);
      case 'last_week':
        from = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7)).toIso8601String();
        break;
      case 'this_month':
        from = DateTime(now.year, now.month, 1).toIso8601String();
        break;
      default:
        from = null;
    }

    var where = <String>[];
    var args = <Object>[];
    if (from != null) {
      where.add('created_at >= ?');
      args.add(from);
    }
    if (category != 'all') {
      where.add('(${_categoryClause(category)})');
    }
    return db.query(
      DbConstants.activityLog,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit,
    );
  }

  static String _categoryClause(String category) {
    switch (category) {
      case 'login':
        return "action LIKE '%login%' OR action LIKE '%logout%' OR entity_type = 'auth'";
      case 'orders':
        return "entity_type IN ('sale','order','purchase') OR action LIKE '%checkout%' OR action LIKE '%sale%'";
      case 'changes':
        return "action LIKE '%update%' OR action LIKE '%edit%' OR action LIKE '%create%' OR action LIKE '%add%'";
      case 'delete':
        return "action LIKE '%delete%' OR action LIKE '%remove%'";
      default:
        return '1=1';
    }
  }
}
