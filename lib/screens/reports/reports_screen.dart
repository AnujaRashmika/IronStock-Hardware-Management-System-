import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  double sales = 0, purchases = 0, expenses = 0, returns = 0;
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    final s = await db.rawQuery('SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.sales}');
    final p = await db.rawQuery('SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.purchases}');
    final e = await db.rawQuery('SELECT COALESCE(SUM(amount),0) as t FROM ${DbConstants.expenses}');
    final r = await db.rawQuery('SELECT COALESCE(SUM(total),0) as t FROM ${DbConstants.returns}');
    sales = (s.first['t'] as num).toDouble();
    purchases = (p.first['t'] as num).toDouble();
    expenses = (e.first['t'] as num).toDouble();
    returns = (r.first['t'] as num).toDouble();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final gross = sales - purchases;
    final net = gross - expenses - returns;
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 16),
        if (loading) const Center(child: CircularProgressIndicator())
        else Expanded(child: ListView(children: [
          _tile('Total Sales', sales, Colors.green),
          _tile('Total Purchases', purchases, Colors.blue),
          _tile('Total Returns', returns, Colors.orange),
          _tile('Total Expenses', expenses, Colors.red),
          const Divider(),
          _tile('Gross Profit (Sales - Purchases)', gross, Colors.teal),
          _tile('Net Profit (Gross - Expenses - Returns)', net, Colors.purple),
          const SizedBox(height: 24),
          const Text('Available Report Types', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          const Wrap(spacing: 8, runSpacing: 8, children: [
            Chip(label: Text('Sales Reports')),
            Chip(label: Text('Purchase Reports')),
            Chip(label: Text('Inventory Reports')),
            Chip(label: Text('Profit Reports')),
            Chip(label: Text('Customer Reports')),
            Chip(label: Text('Return Reports')),
            Chip(label: Text('Warranty Reports')),
            Chip(label: Text('Delivery Reports')),
            Chip(label: Text('Expense Reports')),
          ]),
        ])),
      ])),
    );
  }

  Widget _tile(String title, double value, Color color) => Card(
    child: ListTile(
      title: Text(title),
      trailing: Text(CurrencyUtils.format(value), style: TextStyle(fontWeight: FontWeight.w800, color: color, fontSize: 16)),
    ),
  );
}
