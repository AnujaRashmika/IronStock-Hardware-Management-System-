import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../models/product.dart';
import '../../providers/app_provider.dart';

class WarrantyScreen extends StatefulWidget {
  const WarrantyScreen({super.key});

  @override
  State<WarrantyScreen> createState() => _WarrantyScreenState();
}

class _WarrantyScreenState extends State<WarrantyScreen> {
  String _selectedStatusFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final claims = provider.warrantyClaims.where((w) {
      if (_selectedStatusFilter == 'All') return true;
      return w.status == _selectedStatusFilter;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Warranty Claims Management (${claims.length} Claims)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showNewClaimModal(context, provider),
                icon: const Icon(Icons.verified_user),
                label: const Text('New Warranty Claim'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Filters
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Pending', 'Under Inspection', 'Sent to Supplier', 'Repairing', 'Replaced', 'Completed', 'Rejected']
                  .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: _selectedStatusFilter == status,
                          selectedColor: Colors.teal.shade100,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStatusFilter = status);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: claims.isEmpty
                  ? const Center(child: Text('No warranty claims found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: claims.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final claim = claims[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.teal.shade100,
                            child: Icon(Icons.verified, color: Colors.teal.shade900),
                          ),
                          title: Row(
                            children: [
                              Text('${claim.claimNo} - ${claim.productName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.teal)),
                                child: Text(claim.status, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              'Customer: ${claim.customerName} | S/N: ${claim.serialNumber} | Inv #: ${claim.invoiceNo} | Date: ${DateFormat('dd MMM yyyy').format(claim.dateReceived)}\nIssue: ${claim.issueDescription}'),
                          isThreeLine: true,
                          trailing: DropdownButton<String>(
                            value: claim.status,
                            style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 12),
                            items: ['Pending', 'Received', 'Under Inspection', 'Sent to Supplier', 'Repairing', 'Replaced', 'Completed', 'Rejected']
                                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                .toList(),
                            onChanged: (newStatus) {
                              if (newStatus != null) {
                                provider.updateWarrantyStatus(claim.id, newStatus);
                              }
                            },
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showNewClaimModal(BuildContext context, AppProvider provider) {
    Customer? selectedCust;
    Product? selectedProd;
    final invCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final issueCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Log New Warranty Claim'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Customer>(
                    value: selectedCust,
                    decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder()),
                    items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})'))).toList(),
                    onChanged: (c) => setModalState(() => selectedCust = c),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Product>(
                    value: selectedProd,
                    decoration: const InputDecoration(labelText: 'Product', border: OutlineInputBorder()),
                    items: provider.products.where((p) => p.warrantyMonths > 0 || p.category == 'Power Tools').map((p) => DropdownMenuItem(value: p, child: Text(p.name))).toList(),
                    onChanged: (p) => setModalState(() => selectedProd = p),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: invCtrl, decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Serial Number (S/N)', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: issueCtrl, decoration: const InputDecoration(labelText: 'Issue / Defect Description', border: OutlineInputBorder()), maxLines: 2),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                onPressed: selectedCust == null || selectedProd == null || serialCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        provider.createWarrantyClaim(
                          invoiceNo: invCtrl.text.trim(),
                          customer: selectedCust!,
                          product: selectedProd!,
                          serialNumber: serialCtrl.text.trim(),
                          purchaseDate: DateTime.now().subtract(const Duration(days: 30)),
                          issue: issueCtrl.text.trim(),
                        );
                        Navigator.of(context).pop();
                      },
                child: const Text('Log Warranty Claim'),
              ),
            ],
          );
        },
      ),
    );
  }
}
