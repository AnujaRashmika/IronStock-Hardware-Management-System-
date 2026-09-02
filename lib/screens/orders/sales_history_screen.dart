import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/utils/app_snackbar.dart';
import '../../repositories/sale_repository.dart';
import '../../services/printer_service.dart';
import '../../providers/settings_provider.dart';
import '../../widgets/app_header.dart';
import '../../app/theme.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});
  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final _repo = SaleRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  List<Map<String, dynamic>> _filtered = [];
  Map<String, dynamic>? _selected;
  bool loading = true;
  bool printing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll();
    _filtered = List.from(_list);
    _selected = null;
    setState(() => loading = false);
  }

  void _filter(String q) {
    if (q.trim().isEmpty) {
      _filtered = List.from(_list);
    } else {
      final lower = q.toLowerCase();
      _filtered = _list.where((s) {
        return (s['invoice_no']?.toString() ?? '').toLowerCase().contains(lower) ||
            (s['customer_name']?.toString() ?? '').toLowerCase().contains(lower);
      }).toList();
    }
    setState(() {});
  }

  Future<void> _printSelected() async {
    if (_selected == null) {
      showErrorSnackBar(context, 'Select a sale first');
      return;
    }
    setState(() => printing = true);
    try {
      final settings = context.read<SettingsProvider>();
      final items = await _repo.getItems(_selected!['id'] as int);
      await PrinterService.instance.printSaleBill(
        shopName: settings.shopName,
        shopAddress: settings.shopAddress,
        shopPhone: settings.shopPhone,
        invoiceNo: _selected!['invoice_no']?.toString() ?? '',
        customerName: _selected!['customer_name']?.toString() ?? 'Walk-in',
        date: _selected!['created_at']?.toString().substring(0, 16) ?? '',
        items: items,
        subtotal: (_selected!['subtotal'] as num?)?.toDouble() ?? 0,
        discount: (_selected!['discount'] as num?)?.toDouble() ?? 0,
        tax: (_selected!['tax'] as num?)?.toDouble() ?? 0,
        deliveryCharge: (_selected!['delivery_charge'] as num?)?.toDouble() ?? 0,
        total: (_selected!['total'] as num?)?.toDouble() ?? 0,
        paid: (_selected!['paid_amount'] as num?)?.toDouble() ?? 0,
        balance: (_selected!['balance'] as num?)?.toDouble() ?? 0,
        footer: settings.receiptFooter,
      );
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Print failed: $e');
    }
    if (mounted) setState(() => printing = false);
  }

  Future<void> _showDetails(Map<String, dynamic> sale) async {
    final items = await _repo.getItems(sale['id'] as int);
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sale['invoice_no']?.toString() ?? 'Sale Details'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Customer: ${sale['customer_name'] ?? 'Walk-in'}'),
                Text('Date: ${sale['created_at']?.toString().substring(0, 16) ?? ''}'),
                Text('Status: ${sale['payment_status'] ?? ''}'),
                const Divider(),
                ...items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text('${item['product_name']} × ${item['quantity']}')),
                          Text(CurrencyUtils.format(item['total'] ?? 0)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                    Text(CurrencyUtils.format(sale['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _selected = sale);
              _printSelected();
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const AppHeader(
          title: 'Sales History',
          subtitle: 'View and print past sales',
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
                            hintText: 'Search by invoice or customer...',
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
                        onPressed: (_selected == null || printing) ? null : _printSelected,
                        icon: printing
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.print),
                        label: const Text('Print'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : _filtered.isEmpty
                          ? Center(child: Text('No sales yet.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                          : Card(
                              clipBehavior: Clip.antiAlias,
                              child: ListView.separated(
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) => const Divider(height: 1),
                                itemBuilder: (_, i) {
                                  final s = _filtered[i];
                                  final selected = _selected?['id'] == s['id'];
                                  return InkWell(
                                    onTap: () => setState(() => _selected = s),
                                    onDoubleTap: () => _showDetails(s),
                                    child: Container(
                                      color: selected ? AppTheme.primaryColor.withOpacity(0.08) : null,
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                        leading: CircleAvatar(
                                          backgroundColor: AppColors.greenSoft,
                                          child: Icon(Icons.receipt_long, color: AppColors.green, size: 20),
                                        ),
                                        title: Text(s['invoice_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                        subtitle: Text(
                                          '${s['customer_name'] ?? 'Walk-in'} • ${s['payment_status'] ?? ''}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                        ),
                                        trailing: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            Text(CurrencyUtils.format(s['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                                            if (((s['balance'] as num?) ?? 0) > 0)
                                              Text('Due: ${CurrencyUtils.format(s['balance'])}',
                                                  style: const TextStyle(color: Colors.red, fontSize: 11)),
                                          ],
                                        ),
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
    );
  }
}
