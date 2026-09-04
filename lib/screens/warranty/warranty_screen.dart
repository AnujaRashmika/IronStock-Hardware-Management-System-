import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/warranty_repository.dart';
import '../../providers/product_provider.dart';
import '../../models/product.dart';
import '../../widgets/app_header.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});
  static bool openClaimsTab = false;
  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> with SingleTickerProviderStateMixin {
  final _repo = WarrantyRepository();
  late TabController _tab;
  List<Map<String, dynamic>> warranties = [];
  List<Map<String, dynamic>> claims = [];
  final _itemSearch = TextEditingController();
  final _claimSearch = TextEditingController();
  String claimStatusFilter = 'All';
  String claimPeriod = 'All'; // All | Today | Week | Month | Custom
  DateTimeRange? customRange;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    if (WarrantyScreen.openClaimsTab) {
      _tab.index = 1;
      WarrantyScreen.openClaimsTab = false;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().load();
    });
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    _itemSearch.dispose();
    _claimSearch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    warranties = await _repo.getAll();
    claims = await _repo.getClaims();
    setState(() => loading = false);
  }

  List<Map<String, dynamic>> get filteredWarranties {
    final q = _itemSearch.text.trim().toLowerCase();
    if (q.isEmpty) return warranties;
    return warranties.where((w) {
      return (w['product_name']?.toString() ?? '').toLowerCase().contains(q) ||
          (w['customer_name']?.toString() ?? '').toLowerCase().contains(q) ||
          (w['warranty_no']?.toString() ?? '').toLowerCase().contains(q) ||
          (w['serial_number']?.toString() ?? '').toLowerCase().contains(q);
    }).toList();
  }

  List<Map<String, dynamic>> get filteredClaims {
    var list = List<Map<String, dynamic>>.from(claims);
    if (claimStatusFilter != 'All') {
      list = list.where((c) => (c['status']?.toString() ?? '') == claimStatusFilter).toList();
    }
    final now = DateTime.now();
    if (claimPeriod == 'Today') {
      final start = DateTime(now.year, now.month, now.day);
      list = list.where((c) => _parseDate(c['created_at'])?.isAfter(start.subtract(const Duration(seconds: 1))) ?? false).toList();
    } else if (claimPeriod == 'Week') {
      final start = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      list = list.where((c) => _parseDate(c['created_at'])?.isAfter(start) ?? false).toList();
    } else if (claimPeriod == 'Month') {
      final start = DateTime(now.year, now.month, 1);
      list = list.where((c) => _parseDate(c['created_at'])?.isAfter(start.subtract(const Duration(seconds: 1))) ?? false).toList();
    } else if (claimPeriod == 'Custom' && customRange != null) {
      final s = customRange!.start;
      final e = DateTime(customRange!.end.year, customRange!.end.month, customRange!.end.day, 23, 59, 59);
      list = list.where((c) {
        final d = _parseDate(c['created_at']);
        if (d == null) return false;
        return !d.isBefore(s) && !d.isAfter(e);
      }).toList();
    }
    final q = _claimSearch.text.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) {
        return (c['claim_no']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['product_name']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['customer_name']?.toString() ?? '').toLowerCase().contains(q) ||
            (c['issue']?.toString() ?? '').toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  Color _statusColor(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s == 'pending') return AppColors.orange;
    if (s == 'completed') return AppColors.green;
    if (s == 'rejected') return Colors.red;
    if (s == 'active') return AppColors.green;
    if (s == 'expired') return Colors.grey;
    return Colors.blueGrey;
  }

  Widget _statusChip(String? status) {
    final s = status ?? '-';
    final c = _statusColor(s);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.35)),
      ),
      child: Text(s, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: c)),
    );
  }

  String _fmt(dynamic d) {
    final s = d?.toString() ?? '';
    return s.length > 16 ? s.substring(0, 16) : (s.isEmpty ? '-' : s);
  }

  Future<void> _showWarrantyDetails(Map<String, dynamic> w) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Warranty item')),
            _statusChip(w['status']?.toString()),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Warranty No', w['warranty_no']?.toString() ?? '-'),
              _kv('Product', w['product_name']?.toString() ?? '-'),
              _kv('Customer', w['customer_name']?.toString() ?? '-'),
              _kv('Serial', w['serial_number']?.toString() ?? '-'),
              _kv('Purchase date', _fmt(w['purchase_date'] ?? w['created_at'])),
              _kv('Warranty start', _fmt(w['warranty_start'])),
              _kv('Warranty end', _fmt(w['warranty_end'])),
              _kv('Months', '${w['months'] ?? '-'}'),
              _kv('Status', w['status']?.toString() ?? '-'),
              const SizedBox(height: 8),
              Builder(builder: (_) {
                final end = _parseDate(w['warranty_end']);
                if (end == null) return const SizedBox();
                final valid = end.isAfter(DateTime.now());
                return Text(
                  valid ? 'Warranty is VALID until ${_fmt(w['warranty_end'])}' : 'Warranty EXPIRED on ${_fmt(w['warranty_end'])}',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: valid ? AppColors.green : Colors.red,
                  ),
                );
              }),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Future<void> _showClaimDetails(Map<String, dynamic> c) async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Expanded(child: Text('Claim details')),
            _statusChip(c['status']?.toString()),
          ],
        ),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kv('Claim No', c['claim_no']?.toString() ?? '-'),
              _kv('Product', c['product_name']?.toString() ?? '-'),
              _kv('Customer', c['customer_name']?.toString() ?? '-'),
              _kv('Serial', c['serial_number']?.toString() ?? '-'),
              _kv('Issue', c['issue']?.toString() ?? '-'),
              _kv('Received', _fmt(c['date_received'] ?? c['created_at'])),
              _kv('Resolved', _fmt(c['resolved_at'])),
              _kv('Notes', c['notes']?.toString() ?? '-'),
            ],
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(k, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
        ],
      ),
    );
  }

  Future<void> _newClaim() async {
    final products = context.read<ProductProvider>().products;
    final customer = TextEditingController();
    final productSearch = TextEditingController();
    final serial = TextEditingController();
    final issue = TextEditingController();
    Product? selectedProduct;
    List<Product> productHits = [];

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          void submit() {
            if (customer.text.trim().isEmpty) {
              showErrorSnackBar(context, 'Please fill Customer name');
              return;
            }
            if (productSearch.text.trim().isEmpty && selectedProduct == null) {
              showErrorSnackBar(context, 'Please select a Product');
              return;
            }
            if (issue.text.trim().isEmpty) {
              showErrorSnackBar(context, 'Please fill Issue description');
              return;
            }
            Navigator.pop(ctx, true);
          }

          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.enter): submit,
              const SingleActivator(LogicalKeyboardKey.numpadEnter): submit,
            },
            child: Focus(
              autofocus: true,
              child: AlertDialog(
                title: const Text('New Warranty Claim'),
                content: SizedBox(
                  width: 420,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(controller: customer, decoration: const InputDecoration(labelText: 'Customer name')),
                        const SizedBox(height: 10),
                        TextField(
                          controller: productSearch,
                          decoration: const InputDecoration(labelText: 'Product (type to search)'),
                          onChanged: (v) {
                            final q = v.toLowerCase();
                            setS(() {
                              productHits = products.where((p) => p.name.toLowerCase().contains(q)).take(8).toList();
                              selectedProduct = null;
                            });
                          },
                        ),
                        if (productHits.isNotEmpty)
                          Container(
                            constraints: const BoxConstraints(maxHeight: 140),
                            margin: const EdgeInsets.only(top: 4),
                            decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: productHits.length,
                              itemBuilder: (_, i) {
                                final p = productHits[i];
                                return ListTile(
                                  dense: true,
                                  title: Text(p.name, style: const TextStyle(fontSize: 13)),
                                  onTap: () => setS(() {
                                    selectedProduct = p;
                                    productSearch.text = p.name;
                                    productHits = [];
                                  }),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 10),
                        TextField(controller: serial, decoration: const InputDecoration(labelText: 'Serial (optional)')),
                        const SizedBox(height: 10),
                        TextField(controller: issue, decoration: const InputDecoration(labelText: 'Issue'), maxLines: 2),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                  ElevatedButton(onPressed: submit, child: const Text('Submit')),
                ],
              ),
            ),
          );
        },
      ),
    );

    if (ok != true) return;
    try {
      await _repo.createClaim(
        warrantyId: null,
        customerName: customer.text.trim(),
        productName: selectedProduct?.name ?? productSearch.text.trim(),
        serialNumber: serial.text.trim().isEmpty ? null : serial.text.trim(),
        issue: issue.text.trim(),
      );
      if (mounted) showSuccessSnackBar(context, 'Claim submitted');
      await _load();
      _tab.animateTo(1);
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed: $e');
    }
  }

  Future<void> _pickCustomRange() async {
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: customRange ?? DateTimeRange(start: DateTime.now().subtract(const Duration(days: 30)), end: DateTime.now()),
    );
    if (r != null) {
      setState(() {
        customRange = r;
        claimPeriod = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): _newClaim,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): _newClaim,
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(title: 'Warranty', subtitle: 'Warranty items and claims'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TabBar(
                            controller: _tab,
                            labelColor: AppTheme.primaryColor,
                            tabs: const [Tab(text: 'Warranty Items'), Tab(text: 'Claims')],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _newClaim,
                          icon: const Icon(Icons.add),
                          label: const Text('New Claim'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: loading
                          ? const Center(child: CircularProgressIndicator())
                          : TabBarView(
                              controller: _tab,
                              children: [
                                // Items
                                Column(
                                  children: [
                                    TextField(
                                      controller: _itemSearch,
                                      decoration: InputDecoration(
                                        hintText: 'Search product or customer name...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: filteredWarranties.isEmpty
                                          ? Center(child: Text('No warranty items.', style: TextStyle(color: Colors.grey.shade600)))
                                          : Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: ListView.separated(
                                                itemCount: filteredWarranties.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (_, i) {
                                                  final w = filteredWarranties[i];
                                                  return InkWell(
                                                    onDoubleTap: () => _showWarrantyDetails(w),
                                                    child: ListTile(
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                      leading: CircleAvatar(
                                                        backgroundColor: AppColors.greenSoft,
                                                        child: Icon(Icons.verified_outlined, color: AppTheme.primaryColor, size: 20),
                                                      ),
                                                      title: Text(w['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                      subtitle: Text(
                                                        '${w['customer_name'] ?? ''} • ${w['warranty_no'] ?? ''} • ends ${_fmt(w['warranty_end'])}',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                      ),
                                                      trailing: _statusChip(w['status']?.toString() ?? 'Active'),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                                // Claims
                                Column(
                                  children: [
                                    TextField(
                                      controller: _claimSearch,
                                      decoration: InputDecoration(
                                        hintText: 'Search claim, product, customer...',
                                        prefixIcon: const Icon(Icons.search),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                      onChanged: (_) => setState(() {}),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: claimStatusFilter,
                                            decoration: const InputDecoration(labelText: 'Status', isDense: true),
                                            items: const [
                                              DropdownMenuItem(value: 'All', child: Text('All')),
                                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                              DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                              DropdownMenuItem(value: 'Rejected', child: Text('Rejected')),
                                            ],
                                            onChanged: (v) => setState(() => claimStatusFilter = v ?? 'All'),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: DropdownButtonFormField<String>(
                                            value: claimPeriod,
                                            decoration: const InputDecoration(labelText: 'Period', isDense: true),
                                            items: const [
                                              DropdownMenuItem(value: 'All', child: Text('All')),
                                              DropdownMenuItem(value: 'Today', child: Text('Today')),
                                              DropdownMenuItem(value: 'Week', child: Text('This week')),
                                              DropdownMenuItem(value: 'Month', child: Text('This month')),
                                              DropdownMenuItem(value: 'Custom', child: Text('Custom range')),
                                            ],
                                            onChanged: (v) async {
                                              if (v == 'Custom') {
                                                await _pickCustomRange();
                                              } else {
                                                setState(() => claimPeriod = v ?? 'All');
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Expanded(
                                      child: filteredClaims.isEmpty
                                          ? Center(child: Text('No claims yet.', style: TextStyle(color: Colors.grey.shade600)))
                                          : Card(
                                              clipBehavior: Clip.antiAlias,
                                              child: ListView.separated(
                                                itemCount: filteredClaims.length,
                                                separatorBuilder: (_, __) => const Divider(height: 1),
                                                itemBuilder: (_, i) {
                                                  final c = filteredClaims[i];
                                                  return InkWell(
                                                    onDoubleTap: () => _showClaimDetails(c),
                                                    child: ListTile(
                                                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                                      leading: CircleAvatar(
                                                        backgroundColor: AppColors.orangeSoft,
                                                        child: Icon(Icons.report_problem_outlined, color: AppColors.orange, size: 20),
                                                      ),
                                                      title: Text(c['claim_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                                      subtitle: Text(
                                                        '${c['product_name']} • ${c['customer_name']} • ${c['issue']}',
                                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                                      ),
                                                      trailing: PopupMenuButton<String>(
                                                        onSelected: (s) async {
                                                          await _repo.updateClaimStatus(c['id'] as int, s);
                                                          await _load();
                                                        },
                                                        itemBuilder: (_) => AppConstants.warrantyClaimStatuses
                                                            .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                                            .toList(),
                                                        child: _statusChip(c['status']?.toString()),
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                    ),
                                  ],
                                ),
                              ],
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
