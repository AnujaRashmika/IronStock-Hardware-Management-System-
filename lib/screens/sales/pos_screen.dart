import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/customer.dart';
import '../../providers/app_provider.dart';
import '../../widgets/invoice_dialog.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final filteredProducts = provider.products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.code.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          p.brand.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || p.category == _selectedCategory;
      return matchesSearch && matchesCategory && p.status == 'Active';
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Side: Product Search & Grid
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Top Filter & Search Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: 'Search Product by Name, Code, Barcode or Brand...',
                                prefixIcon: const Icon(Icons.search, color: Colors.orange),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                        },
                                      )
                                    : null,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Category Chips Filter
                      SizedBox(
                        height: 36,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _buildCategoryChip('All'),
                            ...provider.categories.map((c) => _buildCategoryChip(c.name)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Product Grid View
                Expanded(
                  child: filteredProducts.isEmpty
                      ? const Center(child: Text('No products matching search.'))
                      : GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.35,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final prod = filteredProducts[index];
                            final isLowStock = prod.currentStock <= prod.reorderLevel;

                            return InkWell(
                              onTap: () {
                                provider.addToCart(prod);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isLowStock ? Colors.amber.shade300 : Colors.grey.shade200,
                                    width: isLowStock ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(prod.code, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                        ),
                                        Text(
                                          prod.unit,
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      prod.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const Spacer(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Rs. ${prod.sellingPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 13),
                                        ),
                                        Text(
                                          'Stock: ${prod.currentStock.toStringAsFixed(0)}',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isLowStock ? Colors.red : Colors.grey.shade700,
                                            fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 16),

          // Right Side: Billing Cart & Actions
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  // Customer Selection Bar
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: const Color(0xFF1E293B),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.white70),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<Customer>(
                              value: provider.selectedCustomer,
                              dropdownColor: const Color(0xFF1E293B),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              items: provider.customers.map((c) {
                                return DropdownMenuItem<Customer>(
                                  value: c,
                                  child: Text('${c.name} (${c.customerType})'),
                                );
                              }).toList(),
                              onChanged: (c) {
                                if (c != null) provider.setSelectedCustomer(c);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cart Itemized Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.grey.shade100,
                    child: const Row(
                      children: [
                        Expanded(flex: 3, child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Qty / Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        Expanded(flex: 2, child: Text('Total (Rs.)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        SizedBox(width: 30),
                      ],
                    ),
                  ),

                  // Cart Items List
                  Expanded(
                    child: provider.cart.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_outlined, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Cart is empty. Select products to add.', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(8),
                            itemCount: provider.cart.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = provider.cart[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                          Text('${item.product.unit} | Rs. ${item.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => provider.updateCartQty(index, item.quantity - 1),
                                            child: const Icon(Icons.remove_circle_outline, size: 18, color: Colors.red),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              item.quantity.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => provider.updateCartQty(index, item.quantity + 1),
                                            child: const Icon(Icons.add_circle_outline, size: 18, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        item.total.toStringAsFixed(2),
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                      onPressed: () => provider.removeFromCart(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),

                  // Cart Totals Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: Column(
                      children: [
                        _buildCartSummaryRow('Subtotal:', 'Rs. ${provider.cartSubtotal.toStringAsFixed(2)}'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Order Discount:', style: TextStyle(fontSize: 12)),
                            SizedBox(
                              width: 100,
                              height: 30,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  provider.setCartDiscount(double.tryParse(val) ?? 0.0);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Delivery Charge:', style: TextStyle(fontSize: 12)),
                            SizedBox(
                              width: 100,
                              height: 30,
                              child: TextField(
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  border: OutlineInputBorder(),
                                  isDense: true,
                                ),
                                onChanged: (val) {
                                  provider.setCartDeliveryCharge(double.tryParse(val) ?? 0.0);
                                },
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                              'Rs. ${provider.cartTotal.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: provider.cart.isEmpty ? null : () => provider.holdCurrentCart(),
                                child: const Text('Hold Sale', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: provider.cart.isEmpty
                                    ? null
                                    : () {
                                        provider.createQuotation(
                                          customer: provider.selectedCustomer,
                                          items: provider.cart,
                                          discount: provider.cartDiscount,
                                          validDays: 14,
                                        );
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Quotation created successfully!')),
                                        );
                                      },
                                child: const Text('Quotation', style: TextStyle(fontSize: 11)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: provider.cart.isEmpty ? null : () => provider.clearCart(),
                                child: const Text('Clear', style: TextStyle(fontSize: 11, color: Colors.red)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),

                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          onPressed: provider.cart.isEmpty ? null : () => _showCheckoutModal(context, provider),
                          icon: const Icon(Icons.payment_rounded),
                          label: const Text('PAY & CHECKOUT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ],
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

  Widget _buildCategoryChip(String title) {
    final isSelected = _selectedCategory == title;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(title, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
        selected: isSelected,
        selectedColor: Colors.orange,
        onSelected: (selected) {
          if (selected) {
            setState(() {
              _selectedCategory = title;
            });
          }
        },
      ),
    );
  }

  Widget _buildCartSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showCheckoutModal(BuildContext context, AppProvider provider) {
    String paymentMethod = 'Cash';
    final TextEditingController paidController = TextEditingController(text: provider.cartTotal.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final paid = double.tryParse(paidController.text) ?? 0.0;
            final changeOrCredit = paid - provider.cartTotal;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.payments, color: Colors.green),
                  SizedBox(width: 8),
                  Text('Complete Payment'),
                ],
              ),
              content: SizedBox(
                width: 450,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.grey.shade100,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount Due:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('Rs. ${provider.cartTotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    const Text('Select Payment Method:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: ['Cash', 'Card', 'Bank Transfer', 'Credit', 'Mixed Payment'].map((method) {
                        return ChoiceChip(
                          label: Text(method),
                          selected: paymentMethod == method,
                          selectedColor: Colors.green.shade100,
                          onSelected: (selected) {
                            if (selected) {
                              setModalState(() {
                                paymentMethod = method;
                                if (method == 'Credit') {
                                  paidController.text = '0.00';
                                } else {
                                  paidController.text = provider.cartTotal.toStringAsFixed(2);
                                }
                              });
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    const Text('Amount Paid by Customer:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: paidController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: 'Rs. ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setModalState(() {}),
                    ),
                    const SizedBox(height: 12),

                    if (changeOrCredit >= 0)
                      Text(
                        'Change Due to Customer: Rs. ${changeOrCredit.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 14),
                      )
                    else
                      Text(
                        'Outstanding Credit Added: Rs. ${(-changeOrCredit).toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.purple, fontSize: 14),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  onPressed: () async {
                    final sale = await provider.checkoutSale(
                      customer: provider.selectedCustomer,
                      paidAmount: paid,
                      primaryPaymentMethod: paymentMethod,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                      if (sale != null) {
                        showDialog(
                          context: context,
                          builder: (_) => InvoiceDialog(sale: sale, shopSettings: provider.shopSettings),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Confirm Sale & Print Invoice'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
