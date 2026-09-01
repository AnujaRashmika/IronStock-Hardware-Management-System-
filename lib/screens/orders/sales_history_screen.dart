import 'package:flutter/material.dart';
import '../../core/utils/currency_utils.dart';
import '../../repositories/sale_repository.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _repo = SaleRepository();
  List<Map<String, dynamic>> _list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Sales History', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty ? const Center(child: Text('No sales yet'))
          : Card(child: ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final s = _list[i];
                return ListTile(
                  title: Text(s['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${s['customer_name'] ?? 'Walk-in'} • ${s['payment_status']}'),
                  trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(CurrencyUtils.format(s['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w800)),
                    if ((s['balance'] as num? ?? 0) > 0)
                      Text('Due: ${CurrencyUtils.format(s['balance'])}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ]),
                );
              },
            ))),
      ])),
    );
  }
}
