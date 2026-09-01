import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _cats = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    _list = await db.query(DbConstants.expenses, orderBy: 'expense_date DESC');
    _cats = await db.query(DbConstants.expenseCategories);
    setState(() => loading = false);
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    String? catName = _cats.isNotEmpty ? _cats.first['name'] as String : null;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('Add Expense'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          if (_cats.isNotEmpty)
            DropdownButtonFormField<String>(
              value: catName,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _cats.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(),
              onChanged: (v) => setS(() => catName = v),
            ),
          TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
          TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    ));
    if (ok == true && title.text.isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      await db.insert(DbConstants.expenses, {
        'category_name': catName,
        'title': title.text,
        'amount': double.tryParse(amount.text) ?? 0,
        'expense_date': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Expense added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Expenses', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Expense')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty ? const Center(child: Text('No expenses'))
          : Card(child: ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final e = _list[i];
                return ListTile(
                  title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(e['category_name'] ?? ''),
                  trailing: Text(CurrencyUtils.format(e['amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                );
              },
            ))),
      ])),
    );
  }
}
