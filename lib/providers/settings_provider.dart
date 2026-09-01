import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import '../core/database/database_helper.dart';
import '../core/constants/db_constants.dart';

class SettingsProvider extends ChangeNotifier {
  String shopName = 'My Hardware Store';
  String shopAddress = '';
  String shopPhone = '';
  String currency = 'LKR';
  double taxRate = 0;
  String invoicePrefix = 'INV-';
  String receiptFooter = 'Thank you for shopping with us!';

  Future<void> load() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(DbConstants.settings);
    final map = {for (var r in rows) r['key'] as String: r['value'] as String?};
    shopName = map['shop_name'] ?? shopName;
    shopAddress = map['shop_address'] ?? '';
    shopPhone = map['shop_phone'] ?? '';
    currency = map['currency'] ?? 'LKR';
    taxRate = double.tryParse(map['tax_rate'] ?? '0') ?? 0;
    invoicePrefix = map['invoice_prefix'] ?? 'INV-';
    receiptFooter = map['receipt_footer'] ?? receiptFooter;
    notifyListeners();
  }

  Future<void> loadSettings() => load();

  Future<void> save() async {
    final db = await DatabaseHelper.instance.database;
    final data = {
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_phone': shopPhone,
      'currency': currency,
      'tax_rate': taxRate.toString(),
      'invoice_prefix': invoicePrefix,
      'receipt_footer': receiptFooter,
    };
    for (final e in data.entries) {
      await db.insert(
        DbConstants.settings,
        {'key': e.key, 'value': e.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    notifyListeners();
  }
}
