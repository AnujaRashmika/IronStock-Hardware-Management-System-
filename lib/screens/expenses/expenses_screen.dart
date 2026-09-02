import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../widgets/app_header.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});
  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  final _search = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _filtered = [];
  List<Map<String, dynamic>> _cats = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    _list = await db.query(DbConstants.expenses, orderBy: 'expense_date DESC');
    _cats = await db.query(DbConstants.expenseCategories);
    _filtered = List.from(_list);
    setState(() => loading = false);
  }

  void _filter(String q) {
    _filtered = q.trim().isEmpty ? List.from(_list) : _list.where((e) => (e['title']?.toString() ?? '').toLowerCase().contains(q.toLowerCase())).toList();
    setState(() {});
  }

  Future<void> _add() async {
    final title = TextEditingController();
    final amount = TextEditingController();
    String? catName = _cats.isNotEmpty ? _cats.first['name'] as String : null;
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      void save() => Navigator.pop(ctx, true);
      return CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): save,
          const SingleActivator(LogicalKeyboardKey.numpadEnter): save,
        },
        child: Focus(
          autofocus: true,
          child: Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add Expense', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            if (_cats.isNotEmpty)
              DropdownButtonFormField<String>(value: catName, decoration: const InputDecoration(labelText: 'Category'),
                items: _cats.map((c) => DropdownMenuItem(value: c['name'] as String, child: Text(c['name'] as String))).toList(),
                onChanged: (v) => setS(() => catName = v)),
            const SizedBox(height: 10),
            TextField(controller: title, decoration: const InputDecoration(labelText: 'Title')),
            const SizedBox(height: 10),
            TextField(controller: amount, decoration: const InputDecoration(labelText: 'Amount'), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: save, child: const Text('Save'))),
            ]),
          ]),
        ),
          ),
        ),
      );
    }));
    if (ok == true && title.text.isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      await db.insert(DbConstants.expenses, {
        'category_name': catName, 'title': title.text, 'amount': double.tryParse(amount.text) ?? 0,
        'expense_date': DateTime.now().toIso8601String(), 'created_at': DateTime.now().toIso8601String(),
      });
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Expense added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.enter): _add, const SingleActivator(LogicalKeyboardKey.numpadEnter): _add},
      child: Focus(autofocus: true, child: Column(children: [
        const AppHeader(title: 'Expenses', subtitle: 'Track business expenses'),
        Expanded(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
          Row(children: [
            Expanded(child: SizedBox(height: 48, child: TextField(controller: _search, decoration: InputDecoration(hintText: 'Search expenses...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), onChanged: _filter))),
            const SizedBox(width: 16),
            SizedBox(height: 48, child: ElevatedButton.icon(style: appButtonStyle(color: AppColors.green), onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Expense'))),
          ]),
          const SizedBox(height: 24),
          Expanded(child: loading ? const Center(child: CircularProgressIndicator())
            : _filtered.isEmpty ? Center(child: Text('No expenses yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
            : Card(clipBehavior: Clip.antiAlias, child: ListView.separated(
                itemCount: _filtered.length, separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final e = _filtered[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: CircleAvatar(backgroundColor: AppColors.redSoft, child: Icon(Icons.payments_outlined, color: AppColors.red, size: 20)),
                    title: Text(e['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(e['category_name'] ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    trailing: Text(CurrencyUtils.format(e['amount'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                  );
                },
              ))),
        ]))),
      ])),
    );
  }
}
