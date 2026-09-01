import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/app_constants.dart';
import '../../repositories/warranty_repository.dart';
import '../../widgets/app_header.dart';

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
    final ok = await showDialog<bool>(context: context, builder: (ctx) {
      final isDark = Theme.of(ctx).brightness == Brightness.dark;
      return Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: isDark ? const Color(0xFF1A1A1A) : Colors.white, borderRadius: BorderRadius.circular(20)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('New Warranty Claim', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            TextField(controller: customer, decoration: const InputDecoration(labelText: 'Customer')),
            const SizedBox(height: 10),
            TextField(controller: product, decoration: const InputDecoration(labelText: 'Product')),
            const SizedBox(height: 10),
            TextField(controller: serial, decoration: const InputDecoration(labelText: 'Serial Number')),
            const SizedBox(height: 10),
            TextField(controller: issue, decoration: const InputDecoration(labelText: 'Issue'), maxLines: 2),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit'))),
            ]),
          ]),
        ),
      );
    });
    if (ok == true) {
      await _repo.createClaim(warrantyId: null, customerName: customer.text, productName: product.text, serialNumber: serial.text, issue: issue.text);
      await _load();
      if (mounted) showSuccessSnackBar(context, 'Claim created');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      const AppHeader(title: 'Warranty', subtitle: 'Warranty items and claims'),
      Expanded(child: Padding(padding: const EdgeInsets.all(28), child: Column(children: [
        Row(children: [
          Expanded(child: TabBar(controller: _tab, tabs: const [Tab(text: 'Warranty Items'), Tab(text: 'Claims')])),
          const SizedBox(width: 16),
          SizedBox(height: 48, child: ElevatedButton.icon(style: appButtonStyle(color: AppColors.green), onPressed: _newClaim, icon: const Icon(Icons.add), label: const Text('New Claim'))),
        ]),
        const SizedBox(height: 16),
        Expanded(child: loading ? const Center(child: CircularProgressIndicator())
          : TabBarView(controller: _tab, children: [
              warranties.isEmpty
                  ? Center(child: Text('No warranty records yet.', style: TextStyle(color: Colors.grey.shade600)))
                  : Card(clipBehavior: Clip.antiAlias, child: ListView.separated(
                      itemCount: warranties.length, separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final w = warranties[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(backgroundColor: AppColors.indigoSoft, child: Icon(Icons.verified_outlined, color: AppColors.indigo, size: 20)),
                          title: Text(w['product_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${w['customer_name'] ?? ''} • ${w['warranty_no']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: Chip(label: Text(w['status'] ?? '', style: const TextStyle(fontSize: 12))),
                        );
                      },
                    )),
              claims.isEmpty
                  ? Center(child: Text('No claims yet.', style: TextStyle(color: Colors.grey.shade600)))
                  : Card(clipBehavior: Clip.antiAlias, child: ListView.separated(
                      itemCount: claims.length, separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final c = claims[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(backgroundColor: AppColors.orangeSoft, child: Icon(Icons.report_problem_outlined, color: AppColors.orange, size: 20)),
                          title: Text(c['claim_no'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${c['product_name']} • ${c['customer_name']} • ${c['issue']}', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                          trailing: PopupMenuButton<String>(
                            onSelected: (s) async { await _repo.updateClaimStatus(c['id'] as int, s); await _load(); },
                            itemBuilder: (_) => AppConstants.warrantyClaimStatuses.map((s) => PopupMenuItem(value: s, child: Text(s))).toList(),
                            child: Chip(label: Text(c['status'] ?? '', style: const TextStyle(fontSize: 12))),
                          ),
                        );
                      },
                    )),
            ])),
      ]))),
    ]);
  }
}
