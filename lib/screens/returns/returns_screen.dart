import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../repositories/return_repository.dart';
import '../../models/product.dart';
import '../../widgets/app_header.dart';

class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _returnRepo = ReturnRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _returns = [];
  List<Map<String, dynamic>> _filtered = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _returns = await _returnRepo.getAll();
    _filtered = List.from(_returns);
    setState(() => loading = false);
  }

  void _filter(String q) {
    if (q.trim().isEmpty) {
      _filtered = List.from(_returns);
    } else {
      final lower = q.toLowerCase();
      _filtered = _returns.where((r) {
        return (r['return_no']?.toString() ?? '').toLowerCase().contains(lower) ||
            (r['customer_name']?.toString() ?? '').toLowerCase().contains(lower) ||
            (r['invoice_no']?.toString() ?? '').toLowerCase().contains(lower);
      }).toList();
    }
    setState(() {});
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
        builder: (ctx, setS) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sales Return', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      TextField(controller: invoiceCtrl, decoration: const InputDecoration(labelText: 'Original Invoice No')),
                      const SizedBox(height: 10),
                      TextField(controller: customerCtrl, decoration: const InputDecoration(labelText: 'Customer Name')),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Product>(
                        decoration: const InputDecoration(labelText: 'Product'),
                        items: products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.unit})'))).toList(),
                        onChanged: (p) => setS(() {
                          selected = p;
                          priceCtrl.text = p?.sellingPrice.toStringAsFixed(2) ?? '';
                        }),
                      ),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                        const SizedBox(width: 10),
                        Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit Price'), keyboardType: TextInputType.number)),
                      ]),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: reason,
                        decoration: const InputDecoration(labelText: 'Reason'),
                        items: AppConstants.returnReasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                        onChanged: (v) => setS(() => reason = v ?? reason),
                      ),
                      CheckboxListTile(
                        value: isDamaged,
                        onChanged: (v) => setS(() => isDamaged = v ?? false),
                        title: const Text('Item is Damaged / Defective'),
                        subtitle: Text(
                          isDamaged ? 'Stock will NOT be increased' : 'Stock will be increased',
                          style: TextStyle(color: isDamaged ? Colors.red : Colors.green, fontSize: 12, fontWeight: FontWeight.w600),
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
                              .map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                          onChanged: (v) => setS(() => refundMethod = v ?? 'Cash'),
                        ),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
                        const SizedBox(width: 12),
                        Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Process'))),
                      ]),
                    ],
                  ),
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
          isDamaged ? 'Return processed. Damaged — stock not increased.' : 'Return processed. Stock increased.',
        );
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Return failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _newReturn,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _newReturn,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'Returns & Refunds',
              subtitle: 'Damaged items do not restock — good returns increase stock',
            ),
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
                                hintText: 'Search returns...',
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
                            onPressed: _newReturn,
                            icon: const Icon(Icons.add),
                            label: const Text('New Sales Return'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : _filtered.isEmpty
                              ? Center(child: Text('No returns yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                              : Card(
                                  clipBehavior: Clip.antiAlias,
                                  child: ListView.separated(
                                    itemCount: _filtered.length,
                                    separatorBuilder: (_, __) => const Divider(height: 1),
                                    itemBuilder: (_, i) {
                                      final r = _filtered[i];
                                      return ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.orangeSoft,
                                          child: Icon(Icons.assignment_return, color: AppColors.orange, size: 20),
                                        ),
                                        title: Text(r['return_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          '${r['customer_name'] ?? '-'} • ${r['reason'] ?? ''} • ${r['invoice_no'] ?? ''}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        trailing: Text(
                                          CurrencyUtils.format(r['total'] ?? 0),
                                          style: const TextStyle(fontWeight: FontWeight.w600),
                                        ),
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
