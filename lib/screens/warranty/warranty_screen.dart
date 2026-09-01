import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/warranty_repository.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});
  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> with SingleTickerProviderStateMixin {
  final _repo = WarrantyRepository();
  late TabController _tab;
  List<Map<String, dynamic>> warranties = [];
  List<Map<String, dynamic>> claims = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => loading = true);
    warranties = await _repo.getAll();
    claims = await _repo.getClaims();
    setState(() => loading = false);
  }

  Future<void> _newClaim() async {
    final customer = TextEditingController();
    final product = TextEditingController();
    final serial = TextEditingController();
    final issue = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('New Warranty Claim'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: customer, decoration: const InputDecoration(labelText: 'Customer')),
        TextField(controller: product, decoration: const InputDecoration(labelText: 'Product')),
        TextField(controller: serial, decoration: const InputDecoration(labelText: 'Serial Number')),
        TextField(controller: issue, decoration: const InputDecoration(labelText: 'Issue'), maxLines: 2),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit Claim')),
      ],
    ));
    if (ok == true) {
      await _repo.createClaim(
        warrantyId: null,
        customerName: customer.text,
        productName: product.text,
        serialNumber: serial.text,
        issue: issue.text,
      );
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Claim created');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('Warranty', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const Spacer(),
          ElevatedButton.icon(onPressed: _newClaim, icon: const Icon(Icons.add), label: const Text('New Claim')),
        ]),
        TabBar(controller: _tab, tabs: const [Tab(text: 'Warranty Items'), Tab(text: 'Claims')]),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              warranties.isEmpty ? const Center(child: Text('No warranty records (created on sale for products with warranty months)'))
                : ListView.builder(itemCount: warranties.length, itemBuilder: (_, i) {
                    final w = warranties[i];
                    return ListTile(
                      title: Text(w['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${w['customer_name'] ?? ''} • ${w['warranty_no']} • Ends: ${w['warranty_end']?.toString().substring(0, 10) ?? ''}'),
                      trailing: Chip(label: Text(w['status'] ?? '')),
                    );
                  }),
              claims.isEmpty ? const Center(child: Text('No claims'))
                : ListView.builder(itemCount: claims.length, itemBuilder: (_, i) {
                    final c = claims[i];
                    return ListTile(
                      title: Text(c['claim_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: Text('${c['product_name']} • ${c['customer_name']} • ${c['issue']}'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (s) async {
                          await _repo.updateClaimStatus(c['id'] as int, s);
                          await _load();
                        },
                        itemBuilder: (_) => AppConstants.warrantyClaimStatuses
                            .map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                        child: Chip(label: Text(c['status'] ?? '', style: const TextStyle(fontSize: 12))),
                      ),
                    );
                  }),
            ])),
      ])),
    );
  }
}
