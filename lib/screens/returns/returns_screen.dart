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
  static String? pendingStatusFilter;
  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  final _returnRepo = ReturnRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _returns = [];
  List<Map<String, dynamic>> _filtered = [];
  String statusFilter = 'all'; // all | pending | refunded
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (ReturnsScreen.pendingStatusFilter != null) {
      statusFilter = ReturnsScreen.pendingStatusFilter!;
      ReturnsScreen.pendingStatusFilter = null;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
    });
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _returns = await _returnRepo.getAll();
    _applyFilter();
    setState(() => loading = false);
  }

  void _applyFilter() {
    var list = List<Map<String, dynamic>>.from(_returns);
    if (statusFilter == 'pending') {
      list = list.where((r) => (r['status']?.toString().toLowerCase() ?? '') == 'pending').toList();
    } else if (statusFilter == 'refunded') {
      list = list.where((r) {
        final s = (r['status']?.toString().toLowerCase() ?? '');
        return s == 'refunded' || s == 'completed';
      }).toList();
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return (r['return_no']?.toString() ?? '').toLowerCase().contains(q) ||
            (r['customer_name']?.toString() ?? '').toLowerCase().contains(q) ||
            (r['invoice_no']?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    }
    _filtered = list;
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'pending') return AppColors.orange;
    if (s == 'refunded' || s == 'completed') return AppColors.green;
    return Colors.grey;
  }

  Widget _statusChip(String? status) {
    final s = status ?? 'pending';
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        s.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }

  Future<void> _showDetails(Map<String, dynamic> r) async {
    final items = await _returnRepo.getItems(r['id'] as int);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(child: Text('Return details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                      _statusChip(r['status']?.toString()),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(),
                  _detailRow('Return No', r['return_no']?.toString() ?? '-'),
                  _detailRow('Invoice', r['invoice_no']?.toString() ?? '-'),
                  _detailRow('Customer', r['customer_name']?.toString() ?? '-'),
                  _detailRow('Reason', r['reason']?.toString() ?? '-'),
                  _detailRow('Total', CurrencyUtils.format(r['total'] ?? 0)),
                  _detailRow('Date', (r['created_at']?.toString() ?? '').length > 16
                      ? r['created_at'].toString().substring(0, 16)
                      : r['created_at']?.toString() ?? '-'),
                  const SizedBox(height: 12),
                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: items.isEmpty
                        ? Text('No line items', style: TextStyle(color: Colors.grey.shade600))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final it = items[i];
                              final damaged = (it['is_damaged'] as int? ?? 0) == 1;
                              return ListTile(
                                dense: true,
                                title: Text(it['product_name']?.toString() ?? ''),
                                subtitle: Text(
                                  'Qty: ${it['quantity']} × ${CurrencyUtils.format(it['unit_price'] ?? 0)}${damaged ? ' · Damaged' : ''}',
                                  style: TextStyle(fontSize: 12, color: damaged ? Colors.red : Colors.grey.shade600),
                                ),
                                trailing: Text(CurrencyUtils.format(it['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _newReturn() async {
    final products = context.read<ProductProvider>().products;
    Product? selected;
    final productSearch = TextEditingController();
    List<Product> productHits = [];
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
          void process() {
            if (selected == null) {
              showErrorSnackBar(context, 'Please select a product');
              return;
            }
            final qty = double.tryParse(qtyCtrl.text) ?? 0;
            final price = double.tryParse(priceCtrl.text) ?? 0;
            if (qty <= 0 || price < 0) {
              showErrorSnackBar(context, 'Enter valid quantity and price');
              return;
            }
            Navigator.pop(ctx, true);
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): process,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): process,
            },
            child: Focus(
              autofocus: true,
              child: AlertDialog(
                title: const Text('New Sales Return'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: invoiceCtrl, decoration: const InputDecoration(labelText: 'Invoice No (optional)')),
                        const SizedBox(height: 10),
                        TextField(controller: customerCtrl, decoration: const InputDecoration(labelText: 'Customer name')),
                        const SizedBox(height: 10),
                        TextField(
                          controller: productSearch,
                          decoration: InputDecoration(
                            labelText: 'Product (type to search & select)',
                            suffixIcon: selected != null
                                ? IconButton(
                                    icon: const Icon(Icons.close, size: 18),
                                    onPressed: () => setS(() {
                                      selected = null;
                                      productSearch.clear();
                                      productHits = [];
                                    }),
                                  )
                                : const Icon(Icons.search, size: 18),
                          ),
                          onChanged: (v) {
                            final q = v.trim().toLowerCase();
                            setS(() {
                              selected = null;
                              productHits = q.isEmpty
                                  ? []
                                  : products.where((p) => p.name.toLowerCase().contains(q)).take(8).toList();
                            });
                          },
                        ),
                        if (productHits.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 140),
                            margin: const EdgeInsets.only(top: 4, bottom: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: productHits.length,
                              itemBuilder: (_, i) {
                                final p = productHits[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(p.name, style: const TextStyle(fontSize: 13)),
                                  subtitle: Text('${p.sellingPrice}', style: const TextStyle(fontSize: 11)),
                                  onTap: () => setS(() {
                                    selected = p;
                                    productSearch.text = p.name;
                                    priceCtrl.text = p.sellingPrice.toStringAsFixed(2);
                                    productHits = [];
                                  }),
                                );
                              },
                            ),
                          ),
                        if (selected != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),
                            child: Text('Selected: ${selected!.name}', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                          ),
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: TextField(controller: qtyCtrl, decoration: const InputDecoration(labelText: 'Qty'), keyboardType: TextInputType.number)),
                          const SizedBox(width: 10),
                          Expanded(child: TextField(controller: priceCtrl, decoration: const InputDecoration(labelText: 'Unit price'), keyboardType: TextInputType.number)),
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
                          title: const Text('Damaged (do not restock)'),
                          contentPadding: EdgeInsets.zero,
                        ),
                        CheckboxListTile(
                          value: doRefund,
                          onChanged: (v) => setS(() => doRefund = v ?? false),
                          title: const Text('Process refund now'),
                          subtitle: Text(doRefund ? 'Status → Refunded' : 'Status → Pending', style: const TextStyle(fontSize: 12)),
                          contentPadding: EdgeInsets.zero,
                        ),
                        if (doRefund)
                          DropdownButtonFormField<String>(
                            value: refundMethod,
                            decoration: const InputDecoration(labelText: 'Refund method'),
                            items: const [
                              DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                              DropdownMenuItem(value: 'Card', child: Text('Card')),
                              DropdownMenuItem(value: 'Bank Transfer', child: Text('Bank Transfer')),
                            ],
                            onChanged: (v) => setS(() => refundMethod = v ?? 'Cash'),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: process, child: const Text('Process')),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (ok != true || selected == null) return;
    final qty = double.tryParse(qtyCtrl.text) ?? 0;
    final price = double.tryParse(priceCtrl.text) ?? 0;
    try {
      await _returnRepo.createSalesReturn(
        items: [
          {
            'productId': selected!.id,
            'productName': selected!.name,
            'quantity': qty,
            'unitPrice': price,
            'isDamaged': isDamaged,
          }
        ],
        invoiceNo: invoiceCtrl.text.trim().isEmpty ? null : invoiceCtrl.text.trim(),
        customerName: customerCtrl.text.trim().isEmpty ? 'Walk-in' : customerCtrl.text.trim(),
        reason: reason,
        doRefund: doRefund,
        refundAmount: doRefund ? qty * price : 0,
        refundMethod: refundMethod,
        createdBy: context.read<AuthProvider>().currentUser?.id,
      );
      if (mounted) showSuccessSnackBar(context, doRefund ? 'Return recorded as Refunded' : 'Return recorded as Pending');
      await _load();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed: $e');
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
            const AppHeader(title: 'Returns & Refunds', subtitle: 'Damaged items do not restock — good returns increase stock'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 20, 28, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _search,
                            decoration: InputDecoration(
                              hintText: 'Search return no, customer, invoice...',
                              prefixIcon: const Icon(Icons.search),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onChanged: (_) {
                              _applyFilter();
                              setState(() {});
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'all', label: Text('All')),
                            ButtonSegment(value: 'pending', label: Text('Pending')),
                            ButtonSegment(value: 'refunded', label: Text('Refunded')),
                          ],
                          selected: {statusFilter},
                          onSelectionChanged: (s) {
                            setState(() {
                              statusFilter = s.first;
                              _applyFilter();
                            });
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _newReturn,
                          icon: const Icon(Icons.add),
                          label: const Text('New Sales Return'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                                      return InkWell(
                                        onDoubleTap: () => _showDetails(r),
                                        child: ListTile(
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
                                          trailing: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              _statusChip(r['status']?.toString()),
                                              const SizedBox(width: 12),
                                              Text(
                                                CurrencyUtils.format(r['total'] ?? 0),
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
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
