import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/app_provider.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
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
      return matchesSearch && matchesCategory;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Action Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Search products by Name, SKU/Code, Brand...',
                    prefixIcon: Icon(Icons.search, color: Colors.orange),
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedCategory,
                items: ['All', ...provider.categories.map((c) => c.name)].map((cat) {
                  return DropdownMenuItem(value: cat, child: Text('Category: $cat'));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                onPressed: () => _showProductFormModal(context, provider),
                icon: const Icon(Icons.add_box_rounded),
                label: const Text('Add New Product', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Product Table
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filteredProducts.isEmpty
                  ? const Center(child: Text('No products found.'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Code', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Product Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Cost Price (Rs.)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Selling Price (Rs.)', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Stock Level', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Rack / Location', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredProducts.map((prod) {
                            final isLowStock = prod.currentStock <= prod.reorderLevel;

                            return DataRow(
                              cells: [
                                DataCell(Text(prod.code, style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(prod.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      if (prod.brand.isNotEmpty)
                                        Text('Brand: ${prod.brand}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(prod.category)),
                                DataCell(Text(prod.unit)),
                                DataCell(Text(prod.purchasePrice.toStringAsFixed(2))),
                                DataCell(Text(prod.sellingPrice.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isLowStock ? Colors.red.shade100 : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${prod.currentStock.toStringAsFixed(0)} ${prod.unit}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isLowStock ? Colors.red.shade900 : Colors.green.shade900,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(prod.rackLocation.isNotEmpty ? prod.rackLocation : 'N/A')),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit_note_rounded, color: Colors.blue),
                                        onPressed: () => _showProductFormModal(context, provider, product: prod),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: () => provider.deleteProduct(prod.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductFormModal(BuildContext context, AppProvider provider, {Product? product}) {
    final isEditing = product != null;
    final codeCtrl = TextEditingController(text: isEditing ? product.code : 'PRD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}');
    final nameCtrl = TextEditingController(text: isEditing ? product.name : '');
    final brandCtrl = TextEditingController(text: isEditing ? product.brand : '');
    final descCtrl = TextEditingController(text: isEditing ? product.description : '');
    final purchasePriceCtrl = TextEditingController(text: isEditing ? product.purchasePrice.toString() : '0');
    final sellingPriceCtrl = TextEditingController(text: isEditing ? product.sellingPrice.toString() : '0');
    final wholesalePriceCtrl = TextEditingController(text: isEditing ? product.wholesalePrice.toString() : '0');
    final stockCtrl = TextEditingController(text: isEditing ? product.currentStock.toString() : '0');
    final reorderCtrl = TextEditingController(text: isEditing ? product.reorderLevel.toString() : '20');
    final rackCtrl = TextEditingController(text: isEditing ? product.rackLocation : '');
    final warrantyCtrl = TextEditingController(text: isEditing ? product.warrantyMonths.toString() : '0');

    String selectedUnit = isEditing ? product.unit : 'Piece';
    String selectedCat = isEditing
        ? product.category
        : (provider.categories.isNotEmpty ? provider.categories.first.name : 'General');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isEditing ? 'Edit Product' : 'Add New Hardware Product'),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(labelText: 'Product Code / SKU', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Product Name *', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedCat,
                        decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                        items: provider.categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
                        onChanged: (val) {
                          if (val != null) selectedCat = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit of Measure', border: OutlineInputBorder()),
                        items: ['Piece', 'Box', 'Bag', 'Kg', 'Meter', 'Liter', 'Feet', 'Cubic Feet', 'Other']
                            .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) selectedUnit = val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: brandCtrl,
                        decoration: const InputDecoration(labelText: 'Brand / Manufacturer', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: rackCtrl,
                        decoration: const InputDecoration(labelText: 'Rack / Location', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: purchasePriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Purchase Cost Price (Rs.)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: sellingPriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Retail Selling Price (Rs.)', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: wholesalePriceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Wholesale Price (Rs.)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Current Stock Qty', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: reorderCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Reorder / Low Stock Threshold', border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: warrantyCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Warranty Period (Months)', border: OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(labelText: 'Description / Notes', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (nameCtrl.text.trim().isEmpty) return;

              final p = Product(
                id: isEditing ? product.id : 'prod-${DateTime.now().millisecondsSinceEpoch}',
                code: codeCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                category: selectedCat,
                brand: brandCtrl.text.trim(),
                description: descCtrl.text.trim(),
                unit: selectedUnit,
                purchasePrice: double.tryParse(purchasePriceCtrl.text) ?? 0,
                sellingPrice: double.tryParse(sellingPriceCtrl.text) ?? 0,
                wholesalePrice: double.tryParse(wholesalePriceCtrl.text) ?? 0,
                currentStock: double.tryParse(stockCtrl.text) ?? 0,
                reorderLevel: double.tryParse(reorderCtrl.text) ?? 20,
                rackLocation: rackCtrl.text.trim(),
                warrantyMonths: int.tryParse(warrantyCtrl.text) ?? 0,
              );

              provider.saveProduct(p);
              Navigator.of(context).pop();
            },
            child: Text(isEditing ? 'Save Changes' : 'Create Product'),
          ),
        ],
      ),
    );
  }
}
