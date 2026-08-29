import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';
import '../../widgets/invoice_dialog.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final filteredSales = provider.sales.where((s) {
      final matchesSearch = s.invoiceNo.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          s.customerName.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesStatus = _selectedStatus == 'All' || s.paymentStatus == _selectedStatus;
      return matchesSearch && matchesStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search sales by Invoice # or Customer Name...',
                      prefixIcon: Icon(Icons.search, color: Colors.orange),
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 16),
                DropdownButton<String>(
                  value: _selectedStatus,
                  items: ['All', 'Paid', 'Partial', 'Unpaid/Credit'].map((status) {
                    return DropdownMenuItem(value: status, child: Text('Status: $status'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedStatus = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Sales List Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filteredSales.isEmpty
                  ? const Center(child: Text('No sales records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredSales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final sale = filteredSales[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF1E293B),
                            child: Icon(Icons.receipt_rounded, color: Colors.orange, size: 20),
                          ),
                          title: Row(
                            children: [
                              Text(sale.invoiceNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: sale.paymentStatus == 'Paid' ? Colors.green.shade100 : Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  sale.paymentStatus,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: sale.paymentStatus == 'Paid' ? Colors.green.shade900 : Colors.amber.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text('Customer: ${sale.customerName} | Method: ${sale.primaryPaymentMethod} | Date: ${DateFormat('dd MMM yyyy HH:mm').format(sale.date)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text('Rs. ${sale.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text('Paid: Rs. ${sale.paidAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (_) => InvoiceDialog(sale: sale, shopSettings: provider.shopSettings),
                                  );
                                },
                                icon: const Icon(Icons.print_rounded, size: 16),
                                label: const Text('View / Print'),
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
