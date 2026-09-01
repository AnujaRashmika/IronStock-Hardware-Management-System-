import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/return_repository.dart';
import '../../models/product.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _returnRepo = ReturnRepository();
  List<Map<String, dynamic>> _returns = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _returns = await _returnRepo.getAll();
    setState(() => loading = false);
  }

  Future<void> _newReturn() async {
    final products = context.read<ProductProvider>().products;
    Product? selected;
    final qtyCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    String reason = AppConstants.returnReasons.first;
    bool isDamaged = false;
    bool doRefund = true;
    String refundMethod = 'Cash';
    final invoiceCtrl = TextEditingController();
    final customerCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Sales Return'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: invoiceCtrl, decoration: const InputDecoration(labelText: 'Original Invoice No (optional)')),
                  const SizedBox(height: 10),
                  TextField(controller: customerCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<Product>(
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: products
                        .map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.unit})')))
                        .toList(),
                    onChanged: (p) {
                      setS(() {
                        selected = p;
                        priceCtrl.text = p?.sellingPrice.toStringAsFixed(2) ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: reason,
                    decoration: const InputDecoration(labelText: 'Reason'),
                    items: AppConstants.returnReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (v) => setS(() => reason = v ?? reason),
                  ),
                  const SizedBox(height: 8),
                  // CRITICAL: Damaged vs restock
                  CheckboxListTile(
                    value: isDamaged,
                    onChanged: (v) => setS(() => isDamaged = v ?? false),
                    title: const Text('Item is Damaged / Defective'),
                    subtitle: Text(
                      isDamaged
                          ? '⚠ Stock will NOT be increased (damaged)'
                          : '✓ Stock will be increased (restock)',
                      style: TextStyle(
                        color: isDamaged ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                  CheckboxListTile(
                    value: doRefund,
                    onChanged: (v) => setS(() => doRefund = v ?? true),
                    title: const Text('Process Refund'),
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (doRefund)
                    DropdownButtonFormField<String>(
                      value: refundMethod,
                      decoration: const InputDecoration(labelText: 'Refund Method'),
                      items: ['Cash', 'Card', 'Bank Transfer', 'Customer Credit']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setS(() => refundMethod = v ?? 'Cash'),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Process Return')),
          ],
        ),
      ),
    );

    if (ok != true || selected == null) return;
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    if (qty <= 0) {
      showErrorSnackBar(context, 'Invalid quantity');
      return;
    }

    try {
      final auth = context.read<AuthProvider>();
      await _returnRepo.createSalesReturn(
        saleId: null,
        invoiceNo: invoiceCtrl.text.isEmpty ? null : invoiceCtrl.text,
        customerName: customerCtrl.text.isEmpty ? null : customerCtrl.text,
        reason: reason,
        items: [
          {
            'productId': selected!.id,
            'productName': selected!.name,
            'quantity': qty,
            'unitPrice': price,
            'isDamaged': isDamaged,
          }
        ],
        doRefund: doRefund,
        refundAmount: qty * price,
        refundMethod: refundMethod,
        createdBy: auth.currentUser?.id,
      );
      await context.read<ProductProvider>().load();
      await _load();
      if (mounted) {
        showSuccessSnackBar(
          context,
          isDamaged
              ? 'Return processed. Damaged item — stock NOT increased.'
              : 'Return processed. Stock increased.',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Return failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Returns & Refunds', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _newReturn,
                  icon: const Icon(Icons.add),
                  label: const Text('New Sales Return'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Damaged returns do not increase stock. Good returns restock automatically.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : _returns.isEmpty
                  ? const Center(child: Text('No returns yet'))
                  : Card(
                child: ListView.separated(
                  itemCount: _returns.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final r = _returns[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.orangeSoft,
                        child: Icon(Icons.assignment_return, color: AppColors.orange),
                      ),
                      title: Text(r['return_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${r['customer_name'] ?? '-'} • ${r['reason'] ?? ''} • ${r['invoice_no'] ?? ''}'),
                      trailing: Text(CurrencyUtils.format(r['total'] ?? 0),
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
