import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

class WarrantyRepository {
  final _db = DatabaseHelper.instance;

  Future<List<Map<String, dynamic>>> getAll() async {
    final db = await _db.database;
    return db.query(DbConstants.warranties, orderBy: 'created_at DESC');
  }

  Future<List<Map<String, dynamic>>> getClaims() async {
    final db = await _db.database;
    return db.query(DbConstants.warrantyClaims, orderBy: 'created_at DESC');
  }

  Future<int> createClaim({
    required int? warrantyId,
    required String customerName,
    required String productName,
    String? serialNumber,
    required String issue,
    String? notes,
  }) async {
    final db = await _db.database;
    final r = await db.rawQuery('SELECT COUNT(*) as c FROM ${DbConstants.warrantyClaims}');
    final c = (r.first['c'] as int? ?? 0) + 1;
    final claimNo = 'WC-${c.toString().padLeft(5, '0')}';
    return db.insert(DbConstants.warrantyClaims, {
      'claim_no': claimNo,
      'warranty_id': warrantyId,
      'customer_name': customerName,
      'product_name': productName,
      'serial_number': serialNumber,
      'issue': issue,
      'status': 'Pending',
      'date_received': DateTime.now().toIso8601String(),
      'notes': notes,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateClaimStatus(int id, String status) async {
    final db = await _db.database;
    final map = <String, dynamic>{'status': status};
    if (status == 'Completed' || status == 'Rejected' || status == 'Replaced') {
      map['resolved_at'] = DateTime.now().toIso8601String();
    }
    await db.update(DbConstants.warrantyClaims, map, where: 'id = ?', whereArgs: [id]);
  }
}
