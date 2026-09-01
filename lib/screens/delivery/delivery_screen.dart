import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/delivery_repository.dart';
import '../../widgets/app_header.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
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
  void initState() { super.initState(); _load(); }

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

  @override
  Widget build(BuildContext context) {
    final q = _search.text.trim().toLowerCase();
    final shown = q.isEmpty
        ? _list
        : _list.where((d) =>
            (d['delivery_no']?.toString() ?? '').toLowerCase().contains(q) ||
            (d['customer_name']?.toString() ?? '').toLowerCase().contains(q)).toList();

    return Column(children: [
      const AppHeader(title: 'Delivery', subtitle: 'Track and manage deliveries'),
      Expanded(child: Padding(padding: const EdgeInsets.all(28), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: SizedBox(height: 48, child: TextField(
            controller: _search,
            decoration: InputDecoration(hintText: 'Search deliveries...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
            onChanged: (_) => setState(() {}),
          ))),
        ]),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilterChip(label: Text('All (${_counts.values.fold(0, (a, b) => a + b)})'), selected: statusFilter == null, onSelected: (_) { setState(() => statusFilter = null); _load(); }),
          ...AppConstants.deliveryStatuses.map((s) => FilterChip(
            label: Text('$s (${_counts[s] ?? 0})'), selected: statusFilter == s,
            onSelected: (_) { setState(() => statusFilter = s); _load(); },
          )),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : shown.isEmpty ? Center(child: Text('No deliveries.', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)))
          : Card(clipBehavior: Clip.antiAlias, child: ListView.separated(
              itemCount: shown.length, separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = shown[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  leading: CircleAvatar(backgroundColor: AppColors.purpleSoft, child: Icon(Icons.local_shipping_outlined, color: AppColors.purple, size: 20)),
                  title: Text(d['delivery_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${d['customer_name'] ?? ''} • ${d['address'] ?? ''} • ${d['invoice_no'] ?? ''}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  trailing: PopupMenuButton<String>(
                    onSelected: (s) => _updateStatus(d['id'] as int, s),
                    itemBuilder: (_) => AppConstants.deliveryStatuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                    child: Chip(label: Text(d['status'] ?? '', style: const TextStyle(fontSize: 12))),
                  ),
                );
              },
            ))),
      ]))),
    ]);
  }
}
