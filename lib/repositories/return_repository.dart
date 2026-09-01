import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../services/stock_service.dart';

class ReturnRepository {
  final _db = DatabaseHelper.instance;

  Future<String> nextReturnNo() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DbConstants.returns}');
    final c = (r.first['c'] as int? ?? 0) + 1;
    return 'RET-${c.toString().padLeft(6, '0')}';
  }

  /// Process sales return.
  /// If item is damaged (isDamaged=true) → stock NOT increased.
  /// If not damaged / exchange → stock increased (sales_return).
  Future<int> createSalesReturn({
    int? saleId,
    String? invoiceNo,
    int? customerId,
    String? customerName,
    required String reason,
    required List<Map<String, dynamic>> items,
    // each item: productId, productName, quantity, unitPrice, isDamaged
    String? notes,
    int? createdBy,
    bool doRefund = false,
    double refundAmount = 0,
    String refundMethod = 'Cash',
  }) async {
    final db = await _db.database;
    final returnNo = await nextReturnNo();
    final now = DateTime.now().toIso8601String();
    final total = items.fold<double>(
        0, (s, i) => s + ((i['quantity'] as num) * (i['unitPrice'] as num)));

    final returnId = await db.transaction((txn) async {
      final id = await txn.insert(DbConstants.returns, {
        'return_no': returnNo,
        'sale_id': saleId,
        'invoice_no': invoiceNo,
        'customer_id': customerId,
        'customer_name': customerName,
        'return_type': 'sales_return',
        'reason': reason,
        'subtotal': total,
        'total': total,
        'restock': 1,
        'status': 'completed',
        'notes': notes,
        'created_by': createdBy,
        'created_at': now,
      });

      for (final item in items) {
        await txn.insert(DbConstants.returnItems, {
          'return_id': id,
          'product_id': item['productId'],
          'product_name': item['productName'],
          'quantity': item['quantity'],
          'unit_price': item['unitPrice'],
          'total': (item['quantity'] as num) * (item['unitPrice'] as num),
          'is_damaged': (item['isDamaged'] == true) ? 1 : 0,
        });
      }

      if (doRefund && refundAmount > 0) {
        final refundNo = 'REF-${id.toString().padLeft(6, '0')}';
        await txn.insert(DbConstants.refunds, {
          'refund_no': refundNo,
          'return_id': id,
          'sale_id': saleId,
          'amount': refundAmount,
          'refund_method': refundMethod,
          'created_at': now,
        });
      }

      return id;
    });

    // Stock: only non-damaged items go back to stock
    for (final item in items) {
      final isDamaged = item['isDamaged'] == true;
      if (!isDamaged) {
        await StockService.instance.move(
          productId: item['productId'] as int,
          productName: item['productName'] as String,
          type: 'sales_return',
          quantity: (item['quantity'] as num).toDouble(),
          reference: returnNo,
          notes: reason,
          createdBy: createdBy,
        );
      } else {
        // Damaged: record as damage movement (no stock increase)
        await StockService.instance.move(
          productId: item['productId'] as int,
          productName: item['productName'] as String,
          type: 'damage',
          quantity: 0, // already out from original sale; just log
          reference: returnNo,
          notes: 'Damaged return - not restocked. $reason',
          createdBy: createdBy,
        );
      }
    }

    return returnId;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query(DbConstants.returns, orderBy: 'created_at DESC');
  }
}
