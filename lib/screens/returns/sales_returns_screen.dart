import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../models/return_model.dart';
import '../../models/sale.dart';
import '../../providers/app_provider.dart';

class SalesReturnsScreen extends StatefulWidget {
  const SalesReturnsScreen({super.key});

  @override
  State<SalesReturnsScreen> createState() => _SalesReturnsScreenState();
}

class _SalesReturnsScreenState extends State<SalesReturnsScreen> {
  final TextEditingController _invoiceSearchCtrl = TextEditingController();
  Sale? _selectedSale;
  final List<ReturnItem> _returnItems = [];
  String _refundMethod = 'Cash';

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
              const Text('Sales Returns & Refunds', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showNewReturnModal(context, provider),
                icon: const Icon(Icons.assignment_return_rounded),
                label: const Text('Process New Sales Return'),
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
              child: provider.salesReturns.isEmpty
                  ? const Center(child: Text('No sales returns recorded.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.salesReturns.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ret = provider.salesReturns[index];

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.deepOrange,
                            child: Icon(Icons.keyboard_return, color: Colors.white),
                          ),
                          title: Row(
                            children: [
                              Text(ret.returnNo, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('(Invoice #${ret.invoiceNo})', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Text('Customer: ${ret.customerName} | Refund Method: ${ret.refundMethod} | Date: ${DateFormat('dd MMM yyyy HH:mm').format(ret.date)} | ${ret.items.length} Items'),
                          trailing: Text(
                            'Rs. ${ret.totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
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

  void _showNewReturnModal(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          final totalReturnAmt = _returnItems.fold(0.0, (s, i) => s + i.total);

          return AlertDialog(
            title: const Text('Process Sales Return'),
            content: SizedBox(
              width: 600,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _invoiceSearchCtrl,
                            decoration: const InputDecoration(hintText: 'Enter Invoice # (e.g., INV-...)', border: OutlineInputBorder()),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final search = _invoiceSearchCtrl.text.trim();
                            try {
                              final sale = provider.sales.firstWhere((s) => s.invoiceNo.toLowerCase() == search.toLowerCase());
                              setModalState(() {
                                _selectedSale = sale;
                                _returnItems.clear();
                              });
                            } catch (_) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice not found!')));
                            }
                          },
                          child: const Text('Search Invoice'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_selectedSale != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: Colors.grey.shade100,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice #: ${_selectedSale!.invoiceNo} | Customer: ${_selectedSale!.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Date: ${DateFormat('dd MMM yyyy').format(_selectedSale!.date)} | Total: Rs. ${_selectedSale!.totalAmount.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text('Select Items to Return:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ..._selectedSale!.items.map((saleItem) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              children: [
                                Expanded(child: Text('${saleItem.productName} (${saleItem.quantity} ${saleItem.unit})')),
                                ElevatedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      _returnItems.add(ReturnItem(
                                        productId: saleItem.productId,
                                        productCode: saleItem.productCode,
                                        productName: saleItem.productName,
                                        unit: saleItem.unit,
                                        quantity: saleItem.quantity,
                                        unitPrice: saleItem.unitPrice,
                                        reason: 'Wrong Item Delivered',
                                        isDamaged: false,
                                        total: saleItem.total,
                                      ));
                                    });
                                  },
                                  child: const Text('Add Return'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Text('Items Marked for Return:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ..._returnItems.map((r) => ListTile(
                            dense: true,
                            title: Text('${r.productName} (${r.quantity} ${r.unit})'),
                            subtitle: Text('Reason: ${r.reason} | Is Damaged: ${r.isDamaged ? "YES (No stock restore)" : "NO (Restores stock)"}'),
                            trailing: Text('Rs. ${r.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          )),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _refundMethod,
                        decoration: const InputDecoration(labelText: 'Refund Method', border: OutlineInputBorder()),
                        items: ['Cash', 'Card', 'Bank Transfer', 'Customer Credit'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => _refundMethod = val);
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange, foregroundColor: Colors.white),
                onPressed: _selectedSale == null || _returnItems.isEmpty
                    ? null
                    : () async {
                        final targetCust = provider.customers.firstWhere(
                          (c) => c.id == _selectedSale!.customerId,
                          orElse: () => Customer(id: _selectedSale!.customerId, code: 'CUST-000', name: _selectedSale!.customerName),
                        );

                        await provider.processSalesReturn(
                          invoiceNo: _selectedSale!.invoiceNo,
                          customer: targetCust,
                          items: List.from(_returnItems),
                          refundMethod: _refundMethod,
                        );

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Return processed! Refund of Rs. ${totalReturnAmt.toStringAsFixed(2)} issued.')),
                          );
                        }
                      },
                child: const Text('Process Return & Issue Refund'),
              ),
            ],
          );
        },
      ),
    );
  }
}
