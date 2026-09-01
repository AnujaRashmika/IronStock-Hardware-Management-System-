import 'package:flutter/material.dart';
import '../../widgets/page_header.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/delivery_repository.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _repo = DeliveryRepository();
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
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Delivery', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _chip('All', null, _counts.values.fold(0, (a, b) => a + b)),
          ...AppConstants.deliveryStatuses.map((s) => _chip(s, s, _counts[s] ?? 0)),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : _list.isEmpty ? const Center(child: Text('No deliveries'))
          : Card(child: ListView.separated(
              itemCount: _list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final d = _list[i];
                return ListTile(
                  title: Text(d['delivery_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${d['customer_name'] ?? ''} • ${d['address'] ?? ''} • ${d['invoice_no'] ?? ''}'),
                  trailing: PopupMenuButton<String>(
                    initialValue: d['status'] as String?,
                    onSelected: (s) => _updateStatus(d['id'] as int, s),
                    itemBuilder: (_) => AppConstants.deliveryStatuses
                        .map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                    child: Chip(label: Text(d['status'] ?? '', style: const TextStyle(fontSize: 12))),
                  ),
                );
              },
            ))),
      ])),
    );
  }

  Widget _chip(String label, String? status, int count) {
    final selected = statusFilter == status;
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) {
        setState(() => statusFilter = status);
        _load();
      },
    );
  }
}
