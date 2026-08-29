import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class QuotationsScreen extends StatelessWidget {
  const QuotationsScreen({super.key});

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
              const Text(
                'Price Estimations & Quotations',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => provider.setScreen('pos'),
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: const Text('Create Quotation via POS'),
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
              child: provider.quotations.isEmpty
                  ? const Center(child: Text('No quotations generated yet.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.quotations.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final q = provider.quotations[index];
                        final isConverted = q.status == 'Converted';

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.blue,
                            child: Icon(Icons.request_quote_rounded, color: Colors.white, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(q.quotationNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isConverted ? Colors.green.shade100 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  q.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isConverted ? Colors.green.shade900 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              'Customer: ${q.customerName} | Created: ${DateFormat('dd MMM yyyy').format(q.date)} | Valid Till: ${DateFormat('dd MMM yyyy').format(q.validityDate)} | ${q.items.length} Items'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rs. ${q.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 16),
                              if (!isConverted)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () => provider.convertQuotationToSale(q),
                                  icon: const Icon(Icons.shopping_cart_checkout, size: 16),
                                  label: const Text('Convert to Sale'),
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
}
