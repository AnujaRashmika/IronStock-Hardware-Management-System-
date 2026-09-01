import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../models/customer.dart';
import '../../repositories/customer_repository.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});
  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _repo = CustomerRepository();
  List<Customer> _list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    setState(() => loading = false);
  }

  Future<void> _add() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final addr = TextEditingController();
    final credit = TextEditingController(text: '0');
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Add Customer'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'Name *')),
        TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
        TextField(controller: addr, decoration: const InputDecoration(labelText: 'Address')),
        TextField(controller: credit, decoration: const InputDecoration(labelText: 'Credit Limit'), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
      ],
    ));
    if (ok == true && name.text.trim().isNotEmpty) {
      await _repo.insert(Customer(
        name: name.text.trim(), phone: phone.text, address: addr.text,
        creditLimit: double.tryParse(credit.text) ?? 0,
        createdAt: DateTime.now().toIso8601String(),
      ));
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Customer added');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('Customers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const Spacer(),
            ElevatedButton.icon(onPressed: _add, icon: const Icon(Icons.add), label: const Text('Add Customer')),
          ]),
          const SizedBox(height: 16),
          Expanded(child: loading ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty ? const Center(child: Text('No customers'))
            : Card(child: ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final c = _list[i];
                  return ListTile(
                    title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${c.phone ?? ''} • ${c.customerType}'),
                    trailing: c.currentBalance > 0
                        ? Text('Due: ${CurrencyUtils.format(c.currentBalance)}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w700))
                        : const Text('Settled', style: TextStyle(color: Colors.green)),
                  );
                },
              ))),
        ]),
      ),
    );
  }
}
