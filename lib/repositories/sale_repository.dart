import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';
import '../models/cart_item.dart';
import '../services/stock_service.dart';

class SaleRepository {
  final _db = DatabaseHelper.instance;

  Future<String> nextInvoiceNo() async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DbConstants.sales}');
    final c = (r.first['c'] as int? ?? 0) + 1;
    return 'INV-${c.toString().padLeft(6, '0')}';
  }

  Future<int> createSale({
    required List<CartItem> items,
    int? customerId,
    String? customerName,
    double discount = 0,
    double tax = 0,
    double deliveryCharge = 0,
    required double paidAmount,
    required List<Map<String, dynamic>> payments,
    bool isCredit = false,
    String? notes,
    int? createdBy,
    bool createDelivery = false,
    Map<String, dynamic>? deliveryInfo,
  }) async {
    final db = await _db.database;
    final invoiceNo = await nextInvoiceNo();
    final subtotal = items.fold<double>(0, (s, i) => s + i.lineTotal);
    final total = subtotal - discount + tax + deliveryCharge;
    final balance = total - paidAmount;
    final now = DateTime.now().toIso8601String();

    return await db.transaction((txn) async {
      final saleId = await txn.insert(DbConstants.sales, {
        'invoice_no': invoiceNo,
        'customer_id': customerId,
        'customer_name': customerName ?? 'Walk-in',
        'subtotal': subtotal,
        'discount': discount,
        'tax': tax,
        'delivery_charge': deliveryCharge,
        'total': total,
        'paid_amount': paidAmount,
        'balance': balance,
        'payment_status': balance <= 0 ? 'paid' : (paidAmount > 0 ? 'partial' : 'unpaid'),
        'sale_status': 'completed',
        'is_credit': isCredit || balance > 0 ? 1 : 0,
        'notes': notes,
        'created_by': createdBy,
        'created_at': now,
      });

      for (final item in items) {
        await txn.insert(DbConstants.saleItems, {
          'sale_id': saleId,
          'product_id': item.productId,
          'product_name': item.productName,
          'unit': item.unit,
          'quantity': item.quantity,
          'unit_price': item.unitPrice,
          'discount': item.discount,
          'total': item.lineTotal,
        });
      }

      for (final p in payments) {
        await txn.insert(DbConstants.salePayments, {
          'sale_id': saleId,
          'amount': p['amount'],
          'payment_method': p['method'],
          'reference': p['reference'],
          'created_at': now,
        });
      }

      // Customer credit balance
      if (customerId != null && balance > 0) {
        await txn.rawUpdate(
          'UPDATE ${DbConstants.customers} SET current_balance = current_balance + ? WHERE id = ?',
          [balance, customerId],
        );
      }

      return saleId;
    }).then((saleId) async {
      // Stock movements OUTSIDE nested txn (StockService has own txn)
      for (final item in items) {
        await StockService.instance.move(
          productId: item.productId,
          productName: item.productName,
          type: 'sale',
          quantity: item.quantity,
          reference: invoiceNo,
          createdBy: createdBy,
        );
      }

      // Optional delivery
      if (createDelivery && deliveryInfo != null) {
        final dNo = 'DEL-${saleId.toString().padLeft(6, '0')}';
        final db2 = await _db.database;
        await db2.insert(DbConstants.deliveries, {
          'delivery_no': dNo,
          'sale_id': saleId,
          'invoice_no': invoiceNo,
          'customer_id': customerId,
          'customer_name': customerName ?? deliveryInfo['customer_name'],
          'address': deliveryInfo['address'],
          'phone': deliveryInfo['phone'],
          'delivery_date': deliveryInfo['delivery_date'],
          'expected_date': deliveryInfo['expected_date'],
          'driver': deliveryInfo['driver'],
          'vehicle': deliveryInfo['vehicle'],
          'delivery_charge': deliveryCharge,
          'status': 'Pending',
          'notes': deliveryInfo['notes'],
          'created_at': now,
        });
      }

      // Warranty records for products with warranty
      final db3 = await _db.database;
      for (final item in items) {
        final prods = await db3.query(DbConstants.products,
            where: 'id = ?', whereArgs: [item.productId], limit: 1);
        if (prods.isNotEmpty) {
          final months = prods.first['warranty_months'] as int? ?? 0;
          if (months > 0) {
            final start = DateTime.now();
            final end = DateTime(start.year, start.month + months, start.day);
            await db3.insert(DbConstants.warranties, {
              'warranty_no': 'WR-${saleId}-${item.productId}',
              'sale_id': saleId,
              'invoice_no': invoiceNo,
              'customer_id': customerId,
              'customer_name': customerName,
              'product_id': item.productId,
              'product_name': item.productName,
              'purchase_date': now,
              'warranty_start': start.toIso8601String(),
              'warranty_end': end.toIso8601String(),
              'months': months,
              'status': 'active',
              'created_at': now,
            });
          }
        }
      }

      return saleId;
    });
  }

  Future<List<Map<String, dynamic>>> getAll({String? from, String? to}) async {
    final db = await _db.database;
    String where = '1=1';
    List args = [];
    if (from != null) {
      where += ' AND created_at >= ?';
      args.add(from);
    }
    if (to != null) {
      where += ' AND created_at <= ?';
      args.add(to);
    }
    return db.query(DbConstants.sales, where: where, whereArgs: args, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getItems(int saleId) async {
    final db = await _db.database;
    return db.query(DbConstants.saleItems, where: 'sale_id = ?', whereArgs: [saleId]);
  }

  Future<Map<String, dynamic>?> getById(int id) async {
    final db = await _db.database;
    final rows = await db.query(DbConstants.sales, where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : rows.first;
  }
}
