import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/supplier.dart';
import '../../providers/app_provider.dart';

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suppliers Directory (Outstanding: Rs. ${provider.totalSupplierOutstanding.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showSupplierModal(context, provider),
                icon: const Icon(Icons.person_add),
                label: const Text('Add New Supplier'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.suppliers.isEmpty
                  ? const Center(child: Text('No suppliers added yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.suppliers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sup = provider.suppliers[index];
                        final hasBalance = sup.balance > 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(Icons.local_shipping, color: Colors.blue.shade900),
                          ),
                          title: Row(
                            children: [
                              Text(sup.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('(${sup.company})', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            ],
                          ),
                          subtitle: Text('Code: ${sup.code} | Phone: ${sup.phone} | Address: ${sup.address}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Balance Owed: Rs. ${sup.balance.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: hasBalance ? Colors.purple : Colors.green),
                                  ),
                                  Text('Credit Limit: Rs. ${sup.creditLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                                onPressed: () => _showSupplierPaymentModal(context, provider, sup),
                                child: const Text('Pay Supplier'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _showSupplierModal(context, provider, supplier: sup),
                              ),
                            ],
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

  void _showSupplierModal(BuildContext context, AppProvider provider, {Supplier? supplier}) {
    final isEditing = supplier != null;
    final codeCtrl = TextEditingController(text: isEditing ? supplier.code : 'SUP-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController(text: isEditing ? supplier.name : '');
    final compCtrl = TextEditingController(text: isEditing ? supplier.company : '');
    final phoneCtrl = TextEditingController(text: isEditing ? supplier.phone : '');
    final emailCtrl = TextEditingController(text: isEditing ? supplier.email : '');
    final addrCtrl = TextEditingController(text: isEditing ? supplier.address : '');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Supplier' : 'Add New Supplier'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Supplier Code', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Supplier Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: compCtrl, decoration: const InputDecoration(labelText: 'Company / Firm Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final sup = Supplier(
                id: isEditing ? supplier.id : 'sup-${DateTime.now().millisecondsSinceEpoch}',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                company: compCtrl.text.trim(),
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                balance: isEditing ? supplier.balance : 0,
              );
              provider.saveSupplier(sup);
              Navigator.of(context).pop();
            },
            child: const Text('Save Supplier'),
          ),
        ],
      ),
    );
  }

  void _showSupplierPaymentModal(BuildContext context, AppProvider provider, Supplier supplier) {
    final amountCtrl = TextEditingController(text: supplier.balance.toStringAsFixed(2));
    final refCtrl = TextEditingController();
    String paymentMethod = 'Bank Transfer';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Record Payment to ${supplier.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Owed Balance: Rs. ${supplier.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payment Amount (Rs.)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: paymentMethod,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: ['Cash', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) paymentMethod = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference / Cheque #', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              final amt = double.tryParse(amountCtrl.text) ?? 0.0;
              if (amt <= 0) return;

              provider.recordSupplierPayment(
                supplier: supplier,
                amount: amt,
                paymentMethod: paymentMethod,
                reference: refCtrl.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
}
