import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/app_provider.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final filteredCustomers = provider.customers.where((c) {
      return c.name.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
          c.code.toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
          c.phone.contains(_searchCtrl.text);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Search customer by Name, Code, Phone...',
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                onPressed: () => _showCustomerModal(context, provider),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add New Customer', style: TextStyle(fontWeight: FontWeight.bold)),
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
              child: filteredCustomers.isEmpty
                  ? const Center(child: Text('No customers found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredCustomers.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final cust = filteredCustomers[index];
                        final isCreditOwed = cust.balance > 0;

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: Icon(Icons.person, color: Colors.purple.shade900),
                          ),
                          title: Row(
                            children: [
                              Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                child: Text(cust.customerType, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          subtitle: Text('Code: ${cust.code} | Phone: ${cust.phone} | Address: ${cust.address}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Outstanding Credit: Rs. ${cust.balance.toStringAsFixed(2)}',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isCreditOwed ? Colors.purple : Colors.green),
                                  ),
                                  Text('Credit Limit: Rs. ${cust.creditLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              if (isCreditOwed)
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
                                  onPressed: () => provider.setScreen('customer_credit'),
                                  child: const Text('Receive Payment'),
                                ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.grey),
                                onPressed: () => _showCustomerModal(context, provider, customer: cust),
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

  void _showCustomerModal(BuildContext context, AppProvider provider, {Customer? customer}) {
    final isEditing = customer != null;
    final codeCtrl = TextEditingController(text: isEditing ? customer.code : 'CUST-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController(text: isEditing ? customer.name : '');
    final phoneCtrl = TextEditingController(text: isEditing ? customer.phone : '');
    final emailCtrl = TextEditingController(text: isEditing ? customer.email : '');
    final addrCtrl = TextEditingController(text: isEditing ? customer.address : '');
    final limitCtrl = TextEditingController(text: isEditing ? customer.creditLimit.toString() : '50000');
    String type = isEditing ? customer.customerType : 'Regular';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Customer' : 'Add New Customer'),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Customer Code', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Customer Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: type,
                decoration: const InputDecoration(labelText: 'Customer Type', border: OutlineInputBorder()),
                items: ['Walk-in', 'Regular', 'Contractor', 'Company', 'Builder'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (val) {
                  if (val != null) type = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: limitCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Limit (Rs.)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;
              final c = Customer(
                id: isEditing ? customer.id : 'cust-${DateTime.now().millisecondsSinceEpoch}',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                customerType: type,
                phone: phoneCtrl.text.trim(),
                email: emailCtrl.text.trim(),
                address: addrCtrl.text.trim(),
                creditLimit: double.tryParse(limitCtrl.text) ?? 50000,
                balance: isEditing ? customer.balance : 0,
              );
              provider.saveCustomer(c);
              Navigator.of(context).pop();
            },
            child: const Text('Save Customer'),
          ),
        ],
      ),
    );
  }
}
