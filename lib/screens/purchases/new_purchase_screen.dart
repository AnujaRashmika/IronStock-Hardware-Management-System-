import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../models/purchase.dart';
import '../../models/supplier.dart';
import '../../providers/app_provider.dart';

class NewPurchaseScreen extends StatefulWidget {
  const NewPurchaseScreen({super.key});

  @override
  State<NewPurchaseScreen> createState() => _NewPurchaseScreenState();
}

class _NewPurchaseScreenState extends State<NewPurchaseScreen> {
  Supplier? _selectedSupplier;
  final TextEditingController _invoiceNoCtrl = TextEditingController();
  final TextEditingController _discountCtrl = TextEditingController(text: '0');
  final TextEditingController _paidCtrl = TextEditingController(text: '0');
  String _paymentMethod = 'Cash';

  final List<PurchaseItem> _purchaseItems = [];

  Product? _selectedProduct;
  final TextEditingController _qtyCtrl = TextEditingController(text: '1');
  final TextEditingController _costCtrl = TextEditingController(text: '0');

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final subtotal = _purchaseItems.fold(0.0, (s, i) => s + i.total);
    final discount = double.tryParse(_discountCtrl.text) ?? 0.0;
    final total = (subtotal - discount).clamp(0.0, double.infinity);
    final paid = double.tryParse(_paidCtrl.text) ?? 0.0;
    final credit = (total - paid).clamp(0.0, double.infinity);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Item Selection & Cart
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top Supplier Select Bar
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
                        child: DropdownButtonFormField<Supplier>(
                          value: _selectedSupplier,
                          decoration: const InputDecoration(labelText: 'Select Supplier *', border: OutlineInputBorder()),
                          items: provider.suppliers.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.company})'))).toList(),
                          onChanged: (s) => setState(() => _selectedSupplier = s),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _invoiceNoCtrl,
                          decoration: const InputDecoration(labelText: 'Supplier Invoice #', border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Product Entry Row
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
                        flex: 3,
                        child: DropdownButtonFormField<Product>(
                          value: _selectedProduct,
                          decoration: const InputDecoration(labelText: 'Select Product', border: OutlineInputBorder()),
                          items: provider.products.map((p) => DropdownMenuItem(value: p, child: Text('${p.name} (${p.unit})'))).toList(),
                          onChanged: (p) {
                            setState(() {
                              _selectedProduct = p;
                              _costCtrl.text = p?.purchasePrice.toStringAsFixed(2) ?? '0';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          controller: _qtyCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Qty', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _costCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'Unit Cost (Rs.)', border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                        onPressed: () {
                          if (_selectedProduct == null) return;
                          final qty = double.tryParse(_qtyCtrl.text) ?? 1.0;
                          final cost = double.tryParse(_costCtrl.text) ?? _selectedProduct!.purchasePrice;

                          setState(() {
                            _purchaseItems.add(PurchaseItem(
                              productId: _selectedProduct!.id,
                              productCode: _selectedProduct!.code,
                              productName: _selectedProduct!.name,
                              unit: _selectedProduct!.unit,
                              quantity: qty,
                              purchasePrice: cost,
                              total: qty * cost,
                            ));
                            _selectedProduct = null;
                            _qtyCtrl.text = '1';
                            _costCtrl.text = '0';
                          });
                        },
                        icon: const Icon(Icons.add_shopping_cart),
                        label: const Text('Add'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Items List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: _purchaseItems.isEmpty
                        ? const Center(child: Text('No items added to purchase order yet.'))
                        : ListView.separated(
                            itemCount: _purchaseItems.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _purchaseItems[index];
                              return ListTile(
                                title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('${item.quantity} ${item.unit} x Rs. ${item.purchasePrice.toStringAsFixed(2)}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('Rs. ${item.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                                      onPressed: () => setState(() => _purchaseItems.removeAt(index)),
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
          ),

          const SizedBox(width: 20),

          // Right: Summary & Save
          SizedBox(
            width: 350,
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
                  const Text('Purchase Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  _buildSummaryLine('Subtotal:', 'Rs. ${subtotal.toStringAsFixed(2)}'),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _discountCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Purchase Discount (Rs.)', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const Divider(height: 24),
                  _buildSummaryLine('Total Amount:', 'Rs. ${total.toStringAsFixed(2)}', isBold: true),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _paidCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Amount Paid Now (Rs.)', border: OutlineInputBorder()),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                    items: ['Cash', 'Card', 'Bank Transfer', 'Credit'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryLine('Supplier Credit Balance Added:', 'Rs. ${credit.toStringAsFixed(2)}', isBold: true, color: Colors.purple),
                  const Spacer(),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    onPressed: _purchaseItems.isEmpty || _selectedSupplier == null
                        ? null
                        : () async {
                            await provider.addPurchase(
                              supplier: _selectedSupplier!,
                              supplierInvoiceNo: _invoiceNoCtrl.text.trim(),
                              date: DateTime.now(),
                              items: List.from(_purchaseItems),
                              discount: discount,
                              paidAmount: paid,
                              paymentMethod: _paymentMethod,
                            );

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Purchase saved & stock updated successfully!')),
                              );
                              provider.setScreen('purchase_history');
                            }
                          },
                    icon: const Icon(Icons.check_circle_rounded),
                    label: const Text('SAVE & UPDATE STOCK', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryLine(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
      ],
    );
  }
}
