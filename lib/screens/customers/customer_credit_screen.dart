import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../providers/app_provider.dart';

class CustomerCreditScreen extends StatelessWidget {
  const CustomerCreditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final creditCustomers = provider.customers.where((c) => c.balance > 0).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Customer Outstanding Credit Management (Total: Rs. ${provider.totalCustomerOutstanding.toStringAsFixed(2)})',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Outstanding Customers List
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Customers Owed Outstanding Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: creditCustomers.isEmpty
                              ? const Center(child: Text('No customers have pending credit balances.'))
                              : ListView.separated(
                                  itemCount: creditCustomers.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final cust = creditCustomers[index];

                                    return ListTile(
                                      leading: const CircleAvatar(
                                        backgroundColor: Colors.purple,
                                        child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 20),
                                      ),
                                      title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('Code: ${cust.code} | Phone: ${cust.phone} | Type: ${cust.customerType}'),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                'Rs. ${cust.balance.toStringAsFixed(2)}',
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 16),
                                              ),
                                              Text('Limit: Rs. ${cust.creditLimit.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                            ],
                                          ),
                                          const SizedBox(width: 16),
                                          ElevatedButton.icon(
                                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                            onPressed: () => _showPaymentModal(context, provider, cust),
                                            icon: const Icon(Icons.payments, size: 16),
                                            label: const Text('Record Payment'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Right: Customer Payments History Log
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recent Customer Payments Received', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 12),
                        Expanded(
                          child: provider.customerPayments.isEmpty
                              ? const Center(child: Text('No payment records.'))
                              : ListView.separated(
                                  itemCount: provider.customerPayments.length,
                                  separatorBuilder: (_, __) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final pay = provider.customerPayments[index];

                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(Icons.check_circle, color: Colors.green),
                                      title: Text(pay.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text('${pay.paymentMethod} | Date: ${DateFormat('dd MMM HH:mm').format(pay.date)}'),
                                      trailing: Text(
                                        '+ Rs. ${pay.amount.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentModal(BuildContext context, AppProvider provider, Customer customer) {
    final amountCtrl = TextEditingController(text: customer.balance.toStringAsFixed(2));
    final refCtrl = TextEditingController();
    String method = 'Cash';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Receive Credit Payment from ${customer.name}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Outstanding: Rs. ${customer.balance.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Payment Amount (Rs.)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: method,
                decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                items: ['Cash', 'Card', 'Bank Transfer', 'Cheque'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (val) {
                  if (val != null) method = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: refCtrl,
                decoration: const InputDecoration(labelText: 'Reference / Receipt #', border: OutlineInputBorder()),
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

              provider.recordCustomerPayment(
                customer: customer,
                amount: amt,
                paymentMethod: method,
                reference: refCtrl.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Confirm & Update Balance'),
          ),
        ],
      ),
    );
  }
}
