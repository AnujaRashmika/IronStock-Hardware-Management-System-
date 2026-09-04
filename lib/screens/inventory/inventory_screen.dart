import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../providers/inventory_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../app/theme.dart';
import '../../widgets/app_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});
  /// Dashboard → inventory filter bridge
  static String? bridgeFilter;

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchText = '';
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = context.read<InventoryProvider>();
      final bridge = InventoryScreen.bridgeFilter ?? inv.pendingFilter;
      if (bridge != null) {
        setState(() => _filter = bridge);
        InventoryScreen.bridgeFilter = null;
        inv.pendingFilter = null;
      }
      inv.loadInventory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Column(
      children: [
        const AppHeader(
          title: 'Inventory',
          subtitle: 'Manage product stock — add stock only',
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Spacer(),
                    IconButton(
                      tooltip: 'Refresh',
                      onPressed: () => context.read<InventoryProvider>().loadInventory(),
                      icon: const Icon(Icons.refresh),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stat cards
                Consumer<InventoryProvider>(
                  builder: (context, provider, _) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final cardWidth = width > 850 ? (width - 48) / 4 : (width - 16) / 2;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _statCard(width: cardWidth, title: 'Total Products', value: provider.totalProducts.toString(), icon: Icons.inventory_2_outlined),
                            _statCard(width: cardWidth, title: 'In Stock', value: provider.inStockProducts.toString(), icon: Icons.check_circle_outline),
                            _statCard(width: cardWidth, title: 'Low Stock', value: provider.lowStockProducts.toString(), icon: Icons.warning_amber_outlined),
                            _statCard(width: cardWidth, title: 'Out of Stock', value: provider.outOfStockProducts.toString(), icon: Icons.remove_shopping_cart_outlined),
                          ],
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 24),

                // Search + filter
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: TextField(
                          onChanged: (value) => setState(() => _searchText = value.trim().toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Search products...',
                            prefixIcon: const Icon(Icons.search),
                            filled: true,
                            fillColor: cardColor,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.teal, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 48,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _filter,
                            isDense: true,
                            dropdownColor: cardColor,
                            items: const [
                              DropdownMenuItem(value: 'All', child: Text('All')),
                              DropdownMenuItem(value: 'In Stock', child: Text('In Stock')),
                              DropdownMenuItem(value: 'Low Stock', child: Text('Low Stock')),
                              DropdownMenuItem(value: 'Out of Stock', child: Text('Out of Stock')),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _filter = value);
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                // Table
                Expanded(
                  child: Consumer<InventoryProvider>(
                    builder: (context, provider, _) {
                      if (provider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (provider.errorMessage != null) {
                        return Center(child: Text(provider.errorMessage!));
                      }
                      final products = _filteredProducts(provider.products);
                      if (products.isEmpty) return _emptyState();
                      return _inventoryTable(products);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required double width,
    required String title,
    required String value,
    required IconData icon,
  }) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: width,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: dark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: dark ? const Color(0xFF2E2E2E) : const Color(0xFFE6EAE8)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Product> _filteredProducts(List<Product> products) {
    return products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchText);
      if (!matchesSearch) return false;
      switch (_filter) {
        case 'In Stock':
          return product.stockQuantity > product.reorderLevel;
        case 'Low Stock':
          return product.stockQuantity > 0 && product.stockQuantity <= product.reorderLevel;
        case 'Out of Stock':
          return product.stockQuantity <= 0;
        default:
          return true;
      }
    }).toList();
  }

  Widget _inventoryTable(List<Product> products) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? const Color(0xFF2E2E2E) : const Color(0xFFE6EAE8)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          child: DataTable(
            headingRowHeight: 52,
            dataRowMinHeight: 62,
            dataRowMaxHeight: 72,
            columns: const [
              DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Reorder Level', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
              DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
            rows: products.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    InkWell(
                      onDoubleTap: () => _showAddStockDialog(product),
                      child: Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  DataCell(Text(product.unit)),
                  DataCell(Text(product.stockQuantity.toStringAsFixed(
                    product.stockQuantity == product.stockQuantity.roundToDouble() ? 0 : 2,
                  ))),
                  DataCell(Text(product.reorderLevel.toStringAsFixed(0))),
                  DataCell(_statusBadge(product)),
                  DataCell(
                    IconButton(
                      tooltip: 'Add Stock',
                      onPressed: () => _showAddStockDialog(product),
                      icon: const Icon(Icons.add_box_outlined, color: AppColors.green),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(Product product) {
    String text;
    if (product.stockQuantity <= 0) {
      text = 'Out of Stock';
    } else if (product.stockQuantity <= product.reorderLevel) {
      text = 'Low Stock';
    } else {
      text = 'In Stock';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: _statusColor(product).withOpacity(0.10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _statusColor(product)),
      ),
    );
  }

  Color _statusColor(Product product) {
    if (product.stockQuantity <= 0) return Colors.red;
    if (product.stockQuantity <= product.reorderLevel) return Colors.orange;
    return AppColors.teal;
  }

  Future<void> _showAddStockDialog(Product product) async {
    final controller = TextEditingController();
    final quantity = await showDialog<double>(
      context: context,
      builder: (context) {
        void submitStock() {
          final value = double.tryParse(controller.text.trim());
          if (value == null || value <= 0) return;
          Navigator.pop(context, value);
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): submitStock,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): submitStock,
          },
          child: Focus(
            child: AlertDialog(
              title: const Text('Add Stock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'Current stock: ${product.stockQuantity.toStringAsFixed(0)}',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => submitStock(),
                    decoration: const InputDecoration(
                      labelText: 'Quantity to add',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(onPressed: submitStock, child: const Text('Add Stock')),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
    if (quantity == null || !mounted) return;

    final success = await context.read<InventoryProvider>().addStock(product.id!, quantity);
    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(context, '${product.name}: $quantity stock added.');
    } else {
      showErrorSnackBar(context, 'Failed to add stock.');
    }
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 55, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No products found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text('Try changing your search or filter.', style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
