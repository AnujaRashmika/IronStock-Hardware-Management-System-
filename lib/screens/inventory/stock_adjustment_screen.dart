import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/product.dart';
import '../../providers/app_provider.dart';

class StockAdjustmentScreen extends StatefulWidget {
  const StockAdjustmentScreen({super.key});

  @override
  State<StockAdjustmentScreen> createState() => _StockAdjustmentScreenState();
}

class _StockAdjustmentScreenState extends State<StockAdjustmentScreen> {
  Product? _selectedProduct;
  final TextEditingController _actualStockCtrl = TextEditingController();
  final TextEditingController _reasonCtrl = TextEditingController();
  String _adjustmentReason = 'Physical Count Discrepancy';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Adjustment Form
          SizedBox(
            width: 380,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Manual Stock Adjustment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Select Product:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    isExpanded: true,
                    decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.all(12)),
                    hint: const Text('Search & Select Product'),
                    items: provider.products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.unit})'))).toList(),
                    onChanged: (p) {
                      setState(() {
                        _selectedProduct = p;
                        _actualStockCtrl.text = p?.currentStock.toStringAsFixed(0) ?? '0';
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_selectedProduct != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey.shade100,
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('System Stock:'),
                              Text('${_selectedProduct!.currentStock.toStringAsFixed(0)} ${_selectedProduct!.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('Actual Physical Counted Stock:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _actualStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Enter physical count'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Reason:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: _adjustmentReason,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Physical Count Discrepancy', 'Damaged Stock', 'Expired Goods', 'Stolen / Lost Item', 'Other']
                          .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _adjustmentReason = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reasonCtrl,
                      decoration: const InputDecoration(labelText: 'Additional Notes', border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 45),
                      ),
                      onPressed: () {
                        if (_selectedProduct == null) return;
                        final physical = double.tryParse(_actualStockCtrl.text) ?? _selectedProduct!.currentStock;
                        final fullReason = '$_adjustmentReason: ${_reasonCtrl.text.trim()}';

                        provider.adjustStock(
                          productId: _selectedProduct!.id,
                          newPhysicalStock: physical,
                          reason: fullReason,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Stock adjusted successfully!')),
                        );

                        setState(() {
                          _selectedProduct = null;
                          _actualStockCtrl.clear();
                          _reasonCtrl.clear();
                        });
                      },
                      icon: const Icon(Icons.tune_rounded),
                      label: const Text('Save Stock Adjustment'),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Right: Stock Movement Audit History Table
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Centralized Stock Movement Audit History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: provider.stockMovements.isEmpty
                        ? const Center(child: Text('No stock movement logs recorded yet.'))
                        : ListView.separated(
                            itemCount: provider.stockMovements.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final sm = provider.stockMovements[index];
                              final isPositive = sm.quantityDelta > 0;

                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: sm.type == 'Purchase'
                                      ? Colors.blue.shade100
                                      : (sm.type == 'Sale' ? Colors.green.shade100 : Colors.orange.shade100),
                                  child: Icon(
                                    sm.type == 'Purchase'
                                        ? Icons.add_shopping_cart
                                        : (sm.type == 'Sale' ? Icons.point_of_sale : Icons.sync_alt_rounded),
                                    color: sm.type == 'Purchase'
                                        ? Colors.blue.shade900
                                        : (sm.type == 'Sale' ? Colors.green.shade900 : Colors.orange.shade900),
                                    size: 18,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Text(sm.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                                      child: Text(sm.type, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                subtitle: Text('Ref: ${sm.reference} | Reason: ${sm.reason} | Date: ${DateFormat('dd MMM HH:mm').format(sm.date)}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isPositive ? '+' : ''}${sm.quantityDelta.toStringAsFixed(1)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: isPositive ? Colors.green : Colors.red, fontSize: 14),
                                    ),
                                    Text('Stock: ${sm.previousStock.toStringAsFixed(0)} ➔ ${sm.newStock.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
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
        ],
      ),
    );
  }
}
