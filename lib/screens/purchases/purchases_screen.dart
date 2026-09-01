import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/purchase_repository.dart';
import '../../models/product.dart';
import '../../widgets/app_header.dart';

class PurchasesScreen extends StatefulWidget {
  const PurchasesScreen({super.key});
  @override
  State<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends State<PurchasesScreen> {
  final _repo = PurchaseRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    _filtered = List.from(_list);
    setState(() => loading = false);
  }

  void _filter(String q) {
    if (q.trim().isEmpty) {
      _filtered = List.from(_list);
    } else {
      final lower = q.toLowerCase();
      _filtered = _list.where((p) =>
          (p['invoice_no']?.toString() ?? '').toLowerCase().contains(lower) ||
          (p['supplier_name']?.toString() ?? '').toLowerCase().contains(lower)).toList();
    }
    setState(() {});
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

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('New Purchase', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    TextField(controller: invCtrl, decoration: const InputDecoration(labelText: 'Supplier Invoice No')),
                    const SizedBox(height: 10),
                    TextField(controller: supplierCtrl, decoration: const InputDecoration(labelText: 'Supplier Name')),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<Product>(
                      value: selected,
                      decoration: const InputDecoration(labelText: 'Product'),
                      items: products.map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                      onChanged: (p) => setS(() {
                        selected = p;
                        priceCtrl.text = p?.purchasePrice.toString() ?? '0';
                      }),
                    ),
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Cost'), keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                      const SizedBox(width: 12),
                      Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save'))),
                    ]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
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
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _newPurchase,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _newPurchase,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(title: 'Purchases', subtitle: 'Purchases automatically increase stock'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _search,
                              decoration: InputDecoration(
                                hintText: 'Search purchases...',
                                prefixIcon: const Icon(Icons.search),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: _filter,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: appButtonStyle(color: AppColors.green),
                            onPressed: _newPurchase,
                            icon: const Icon(Icons.add),
                            label: const Text('New Purchase'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(child: Text('No purchases yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final p = _filtered[i];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.blueSoft,
                                          child: Icon(Icons.shopping_cart_outlined, color: AppColors.blue, size: 20),
                                        ),
                                        title: Text(p['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(p['supplier_name'] ?? '-', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                        trailing: Text(CurrencyUtils.format(p['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                                      );
                                    },
                                  ),
                                ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
