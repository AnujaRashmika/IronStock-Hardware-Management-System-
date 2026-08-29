import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class RefundsScreen extends StatelessWidget {
  const RefundsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Customer Refund Transactions History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.refunds.isEmpty
                  ? const Center(child: Text('No refunds issued yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.refunds.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final r = provider.refunds[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.red,
                            child: Icon(Icons.money_off, color: Colors.white),
                          ),
                          title: Text('Refund for Return #${r.returnNo} (${r.customerName})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Invoice #: ${r.invoiceNo} | Refund Method: ${r.refundMethod} | Date: ${DateFormat('dd MMM yyyy HH:mm').format(r.date)}'),
                          trailing: Text(
                            '- Rs. ${r.amount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.red),
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
