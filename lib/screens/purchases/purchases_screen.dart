import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import 'package:provider/provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/purchase_repository.dart';
import '../../models/product.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _repo = PurchaseRepository();
  List<Map<String, dynamic>> _list = [];
  bool loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    setState(() => loading = false);
  }

  Future<void> _newPurchase() async {
    final products = context.read<ProductProvider>().products;
    if (products.isEmpty) {
      showErrorSnackBar(context, 'Add products first');
      return;
    }
    Product? selected = products.first;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController(text: selected.purchasePrice.toString());
    final invCtrl = TextEditingController();
    final supplierCtrl = TextEditingController();

    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        title: const Text('New Purchase'),
        content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: invCtrl, decoration: const InputDecoration(labelText: 'Supplier Invoice No')),
          TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier Name')),
          const SizedBox(height: 8),
          DropdownButtonFormField<Product>(
            value: selected,
            decoration: const InputDecoration(labelText: 'Product'),
            items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
            onChanged: (p) => setS(() {
              selected = p;
              priceCtrl.text = p?.purchasePrice.toString() ?? '0';
            }),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
            const SizedBox(width: 8),
            Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Cost'), keyboardType: TextInputType.number)),
          ]),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save Purchase')),
        ],
      ),
    ));

    if (ok != true || selected == null) return;
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0) return;

    try {
      await _repo.createPurchase(
        invoiceNo: invCtrl.text.isEmpty ? 'PO-${DateTime.now().millisecondsSinceEpoch}' : invCtrl.text,
        supplierName: supplierCtrl.text,
        items: [{'productId': selected!.id, 'productName': selected!.name, 'unit': selected!.unit, 'quantity': qty, 'unitPrice': price}],
        paidAmount: qty * price,
        createdBy: context.read<AuthProvider>().currentUser?.id,
      );
      await context.read<ProductProvider>().load();
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Purchase saved. Stock increased.');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Purchases', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const Spacer(),
          ElevatedButton.icon(onPressed: _newPurchase, icon: const Icon(Icons.add), label: const Text('New Purchase')),
        ]),
        const SizedBox(height: 8),
        Text('Purchases automatically increase stock', style: TextStyle(color: Colors.grey.shade600)),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty ? const Center(child: Text('No purchases yet'))
          : Card(child: ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = _list[i];
                return ListTile(
                  title: Text(p['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(p['supplier_name'] ?? '-'),
                  trailing: Text(CurrencyUtils.format(p['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w700)),
                );
              },
            ))),
      ])),
    );
  }
}
