import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../repositories/delivery_repository.dart';
import '../../widgets/app_header.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
  static String? pendingStatusFilter;
  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _repo = DeliveryRepository();
  final _search = TextEditingController();
  List<Map<String, dynamic>> _list = [];
  Map<String, int> _counts = {};
  String? statusFilter;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    if (DeliveryScreen.pendingStatusFilter != null) {
      statusFilter = DeliveryScreen.pendingStatusFilter;
      DeliveryScreen.pendingStatusFilter = null;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    _list = await _repo.getAll(status: statusFilter);
    _counts = await _repo.counts();
    setState(() => loading = false);
  }

  Future<void> _updateStatus(int id, String status) async {
    await _repo.updateStatus(id, status, receivedBy: status == 'Delivered' ? 'Customer' : null);
    await _load();
    if (mounted) showSuccessSnackBar(context, 'Status updated to $status');
  }

  Future<void> _showDetails(Map<String, dynamic> d) async {
    final db = await DatabaseHelper.instance.database;
    List<Map<String, dynamic>> items = [];
    final saleId = d['sale_id'] as int?;
    if (saleId != null) {
      items = await db.query(DbConstants.saleItems, where: 'sale_id = ?', whereArgs: [saleId]);
    }

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.purpleSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.local_shipping_outlined, color: AppColors.purple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d['delivery_no']?.toString() ?? 'Delivery',
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text(d['status']?.toString() ?? '', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const Divider(height: 24),
                  _detailRow(Icons.person_outline, 'Customer', d['customer_name']?.toString() ?? '-'),
                  _detailRow(Icons.phone_outlined, 'Mobile', d['phone']?.toString() ?? '-'),
                  _detailRow(Icons.location_on_outlined, 'Address', d['address']?.toString() ?? '-'),
                  _detailRow(Icons.receipt_long_outlined, 'Invoice', d['invoice_no']?.toString() ?? '-'),
                  if (d['notes'] != null && d['notes'].toString().isNotEmpty)
                    _detailRow(Icons.notes_outlined, 'Notes', d['notes'].toString()),
                  const SizedBox(height: 12),
                  const Text('Products', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: items.isEmpty
                        ? Text('No linked sale items', style: TextStyle(color: Colors.grey.shade600, fontSize: 13))
                        : ListView.separated(
                            itemCount: items.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final it = items[i];
                              return ListTile(
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                                title: Text(it['product_name']?.toString() ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                                subtitle: Text('Qty: ${it['quantity']}', style: const TextStyle(fontSize: 12)),
                                trailing: Text(
                                  CurrencyUtils.format(it['total'] ?? 0),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              );
                            },
                          ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          SizedBox(width: 80, child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? _list
        : _list.where((d) =>
            (d['delivery_no']?.toString() ?? '').toLowerCase().contains(q) ||
            (d['customer_name']?.toString() ?? '').toLowerCase().contains(q) ||
            (d['phone']?.toString() ?? '').contains(q)).toList();

    return Column(children: [
      const AppHeader(title: 'Delivery', subtitle: 'Track and manage deliveries'),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: 'Search deliveries...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: Text('All (${_counts.values.fold(0, (a, b) => a + b)})'),
                    selected: statusFilter == null,
                    onSelected: (_) {
                      setState(() => statusFilter = null);
                      _load();
                    },
                  ),
                  ...AppConstants.deliveryStatuses.map((s) => FilterChip(
                        label: Text('$s (${_counts[s] ?? 0})'),
                        selected: statusFilter == s,
                        onSelected: (_) {
                          setState(() => statusFilter = s);
                          _load();
                        },
                      )),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : shown.isEmpty
                        ? Center(child: Text('No deliveries.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
                        : Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              itemCount: shown.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (_, i) {
                                final d = shown[i];
                                return InkWell(
                                  onDoubleTap: () => _showDetails(d),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.purpleSoft,
                                      child: Icon(Icons.local_shipping_outlined, color: AppColors.purple, size: 20),
                                    ),
                                    title: Text(d['delivery_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      '${d['customer_name'] ?? ''} • ${d['phone'] ?? ''} • ${d['address'] ?? ''}',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: PopupMenuButton<String>(
                                      onSelected: (s) => _updateStatus(d['id'] as int, s),
                                      itemBuilder: (_) => AppConstants.deliveryStatuses
                                          .map((s) => PopupMenuItem(value: s, child: Text(s)))
                                          .toList(),
                                      child: Chip(label: Text(d['status'] ?? '', style: const TextStyle(fontSize: 12))),
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
    ]);
  }
}
