import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

/// Centralized stock movement — NEVER update stock manually outside this service.
class StockService {
  StockService._();
  static final StockService instance = StockService._();
  final _db = DatabaseHelper.instance;

  /// type: purchase | sale | sales_return | purchase_return | damage | adjustment
  Future<void> move({
    required int productId,
    required String productName,
    required String type,
    required double quantity,
    String? reference,
    String? notes,
    int? createdBy,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      final rows = await txn.query(
        DbConstants.products,
        columns: ['stock_quantity'],
        where: 'id = ?',
        whereArgs: [productId],
      );
      if (rows.isEmpty) throw Exception('Product not found');

      double current = (rows.first['stock_quantity'] as num).toDouble();
      double delta = 0;

      switch (type) {
        case 'purchase':
        case 'sales_return':
          delta = quantity; // increase
          break;
        case 'sale':
        case 'purchase_return':
        case 'damage':
          delta = -quantity; // decrease
          break;
        case 'adjustment':
          delta = quantity; // can be +/- 
          break;
        default:
          throw Exception('Unknown stock movement type: $type');
      }

      final newQty = current + delta;
      if (newQty < 0 && type != 'adjustment') {
        throw Exception('Insufficient stock for $productName (have $current, need $quantity)');
      }

      await txn.update(
        DbConstants.products,
        {
          'stock_quantity': newQty < 0 ? 0 : newQty,
          'updated_at': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [productId],
      );

      await txn.insert(DbConstants.stockMovements, {
        'product_id': productId,
        'product_name': productName,
        'type': type,
        'quantity': delta,
        'reference': reference,
        'notes': notes,
        'created_by': createdBy,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }
}
