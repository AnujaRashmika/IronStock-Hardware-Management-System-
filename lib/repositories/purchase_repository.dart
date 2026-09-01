import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../services/stock_service.dart';

class PurchaseRepository {
  final _db = DatabaseHelper.instance;

  Future<int> createPurchase({
    required String invoiceNo,
    int? supplierId,
    String? supplierName,
    required List<Map<String, dynamic>> items,
    double discount = 0,
    double tax = 0,
    double paidAmount = 0,
    String? notes,
    int? createdBy,
  }) async {
    final db = await _db.database;
    final now = DateTime.now().toIso8601String();
    final subtotal = items.fold<double>(
        0, (s, i) => s + ((i['quantity'] as num) * (i['unitPrice'] as num)));
    final total = subtotal - discount + tax;
    final balance = total - paidAmount;

    final purchaseId = await db.transaction((txn) async {
      final id = await txn.insert(DbConstants.purchases, {
        'invoice_no': invoiceNo,
        'supplier_id': supplierId,
        'supplier_name': supplierName,
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'total': total,
        'paid_amount': paidAmount,
        'balance': balance,
        'payment_status': balance <= 0 ? 'paid' : 'partial',
        'notes': notes,
        'purchase_date': now,
        'created_by': createdBy,
        'created_at': now,
      });

      for (final item in items) {
        await txn.insert(DbConstants.purchaseItems, {
          'purchase_id': id,
          'product_id': item['productId'],
          'product_name': item['productName'],
          'unit': item['unit'],
          'quantity': item['quantity'],
          'unit_price': item['unitPrice'],
          'discount': item['discount'] ?? 0,
          'total': (item['quantity'] as num) * (item['unitPrice'] as num),
        });
      }

      if (supplierId != null && balance > 0) {
        await txn.rawUpdate(
          'UPDATE ${DbConstants.suppliers} SET current_balance = current_balance + ? WHERE id = ?',
          [balance, supplierId],
        );
      }
      return id;
    });

    for (final item in items) {
      await StockService.instance.move(
        productId: item['productId'] as int,
        productName: item['productName'] as String,
        type: 'purchase',
        quantity: (item['quantity'] as num).toDouble(),
        reference: invoiceNo,
        createdBy: createdBy,
      );
    }
    return purchaseId;
  }

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query(DbConstants.purchases, orderBy: 'created_at DESC');
  }
}
