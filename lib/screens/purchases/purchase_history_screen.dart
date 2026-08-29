import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class PurchaseHistoryScreen extends StatelessWidget {
  const PurchaseHistoryScreen({super.key});

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
              const Text('Purchase Invoices History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => provider.setScreen('new_purchase'),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('New Purchase Entry'),
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
              child: provider.purchases.isEmpty
                  ? const Center(child: Text('No purchase records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.purchases.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final pur = provider.purchases[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.inventory, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Text(pur.purchaseNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (pur.supplierInvoiceNo.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text('(Inv #${pur.supplierInvoiceNo})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ],
                          ),
                          subtitle: Text('Supplier: ${pur.supplierName} | Date: ${DateFormat('dd MMM yyyy HH:mm').format(pur.date)} | Method: ${pur.paymentMethod}'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('Rs. ${pur.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text('Paid: Rs. ${pur.paidAmount.toStringAsFixed(2)} | Credit: Rs. ${pur.creditAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
}
