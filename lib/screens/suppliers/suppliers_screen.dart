import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../models/supplier.dart';

class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});
  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  List<Supplier> _list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(DbConstants.suppliers, orderBy: 'name ASC');
    _list = rows.map(Supplier.fromMap).toList();
    setState(() => loading = false);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final company = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Supplier'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
        TextField(controller: company, decoration: const InputDecoration(labelText: 'Company')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      final db = await DatabaseHelper.instance.database;
      await db.insert(DbConstants.suppliers, Supplier(
        name: name.text.trim(), company: company.text, phone: phone.text,
        createdAt: DateTime.now().toIso8601String(),
      ).toMap()..remove('id'));
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Supplier added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Suppliers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Supplier')),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty ? const Center(child: Text('No suppliers'))
          : Card(child: ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _list[i];
                return ListTile(
                  title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${s.company ?? ''} • ${s.phone ?? ''}'),
                  trailing: s.currentBalance > 0
                      ? Text('Due: ${CurrencyUtils.format(s.currentBalance)}', style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.w700))
                      : null,
                );
              },
            ))),
      ])),
    );
  }
}
