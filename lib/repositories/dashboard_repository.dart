import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

class DashboardRepository {
  final _db = DatabaseHelper.instance;

  Future<Map<String, dynamic>> getStats() async {
    final db = await _db.database;
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day).toIso8601String();
    final end = DateTime(today.year, today.month, today.day, 23, 59, 59).toIso8601String();

    final sales = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) as t, COUNT(*) as c FROM ${DbConstants.sales} WHERE created_at BETWEEN ? AND ?',
      [start, end],
    );
    final purchases = await db.rawQuery(
      'SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.purchases} WHERE created_at BETWEEN ? AND ?',
      [start, end],
    );
    final expenses = await db.rawQuery(
      'SELECT COALESCE(SUM(amount),0) as t FROM ${DbConstants.expenses} WHERE expense_date BETWEEN ? AND ?',
      [start, end],
    );
    final lowStock = await db.rawQuery(
      'SELECT COUNT(*) as c FROM ${DbConstants.products} WHERE is_active=1 AND stock_quantity <= reorder_level',
    );
    final pendingDel = await db.rawQuery(
      "SELECT COUNT(*) as c FROM ${DbConstants.deliveries} WHERE status IN ('Pending','Scheduled','Out for Delivery')",
    );
    final pendingRet = await db.rawQuery(
      "SELECT COUNT(*) as c FROM ${DbConstants.returns} WHERE date(created_at) = date('now')",
    );
    final claims = await db.rawQuery(
      "SELECT COUNT(*) as c FROM ${DbConstants.warrantyClaims} WHERE status='Pending'",
    );
    final outstanding = await db.rawQuery(
      'SELECT COALESCE(SUM(current_balance),0) as t FROM ${DbConstants.customers} WHERE current_balance > 0',
    );

    final todaySales = (sales.first['t'] as num).toDouble();
    final todayPurchases = (purchases.first['t'] as num).toDouble();
    final todayExpenses = (expenses.first['t'] as num).toDouble();
    // rough profit: sales - purchases share - expenses (simplified)
    final profit = todaySales - todayPurchases * 0.7 - todayExpenses;

    return {
      'todaySales': todaySales,
      'todayPurchases': todayPurchases,
      'todayProfit': profit,
      'pendingPayments': (outstanding.first['t'] as num).toDouble(),
      'lowStock': lowStock.first['c'] as int,
      'pendingDeliveries': pendingDel.first['c'] as int,
      'pendingReturns': pendingRet.first['c'] as int,
      'warrantyClaims': claims.first['c'] as int,
      'salesCount': sales.first['c'] as int,
    };
  }

  Future<List<Map<String, dynamic>>> recentSales({int limit = 10}) async {
    final db = await _db.database;
    return db.query(DbConstants.sales, orderBy: 'created_at DESC', limit: limit);
  }

  Future<List<Map<String, dynamic>>> recentPurchases({int limit = 5}) async {
    final db = await _db.database;
    return db.query(DbConstants.purchases, orderBy: 'created_at DESC', limit: limit);
  }
}
