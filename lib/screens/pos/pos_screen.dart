import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../app/theme.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../core/constants/app_constants.dart';
import '../../models/product.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/sale_repository.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});
  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final _searchCtrl = TextEditingController();
  final _saleRepo = SaleRepository();
  List<Product> _filtered = [];
  bool _checkingOut = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prods = context.read<ProductProvider>().products.where((p) => p.isActive).toList();
      setState(() => _filtered = prods);
    });
  }

  void _onSearch(String q) {
    final all = context.read<ProductProvider>().products.where((p) => p.isActive).toList();
    setState(() {
      _filtered = q.isEmpty
          ? all
          : all.where((p) =>
              p.name.toLowerCase().contains(q.toLowerCase()) ||
              (p.sku ?? '').toLowerCase().contains(q.toLowerCase()) ||
              (p.barcode ?? '').contains(q)).toList();
    });
  }

  Future<void> _checkout() async {
    final cart = context.read<CartProvider>();
    if (cart.items.isEmpty) {
      showErrorSnackBar(context, 'Cart is empty');
      return;
    }

    final paidCtrl = TextEditingController(text: cart.total.toStringAsFixed(2));
    String method = 'Cash';
    bool needDelivery = false;
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Checkout'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Total: ${CurrencyUtils.format(cart.total)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: method,
                  decoration: const InputDecoration(labelText: 'Payment Method'),
                  items: AppConstants.paymentMethods
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setS(() => method = v ?? 'Cash'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: paidCtrl,
                  decoration: const InputDecoration(labelText: 'Paid Amount'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: needDelivery,
                  onChanged: (v) => setS(() => needDelivery = v ?? false),
                  title: const Text('Create Delivery'),
                  contentPadding: EdgeInsets.zero,
                ),
                if (needDelivery) ...[
                  TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Delivery Address')),
                  const SizedBox(height: 8),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone')),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Complete Sale')),
          ],
        ),
      ),
    );

    if (ok != true || !mounted) return;
    setState(() => _checkingOut = true);
    try {
      final paid = double.tryParse(paidCtrl.text) ?? cart.total;
      final auth = context.read<AuthProvider>();
      await _saleRepo.createSale(
        items: cart.items,
        customerId: cart.customerId,
        customerName: cart.customerName,
        discount: cart.discount,
        tax: cart.tax,
        deliveryCharge: cart.deliveryCharge,
        paidAmount: paid,
        payments: [
          {'amount': paid, 'method': method, 'reference': null},
        ],
        isCredit: paid < cart.total,
        createdBy: auth.currentUser?.id,
        createDelivery: needDelivery,
        deliveryInfo: needDelivery
            ? {
                'address': addrCtrl.text,
                'phone': phoneCtrl.text,
                'customer_name': cart.customerName,
              }
            : null,
      );
      cart.clear();
      await context.read<ProductProvider>().load();
      if (mounted) showSuccessSnackBar(context, 'Sale completed successfully');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Sale failed: $e');
    }
    setState(() => _checkingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    return Scaffold(
      body: Row(
        children: [
          // Products
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('New Sale (POS)', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search product name, SKU, barcode...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      ),
                    ),
                    onChanged: _onSearch,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No products found. Add products first.'))
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              childAspectRatio: 1.4,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) {
                              final p = _filtered[i];
                              return Card(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: p.stockQuantity <= 0
                                      ? null
                                      : () => context.read<CartProvider>().addProduct(p),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700)),
                                        const Spacer(),
                                        Text(CurrencyUtils.format(p.sellingPrice),
                                            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w700)),
                                        Text('Stock: ${p.stockQuantity} ${p.unit}',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: p.isOutOfStock
                                                    ? Colors.red
                                                    : p.isLowStock
                                                        ? Colors.orange
                                                        : Colors.grey)),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
          // Cart
          Container(
            width: 340,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Text('Cart', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      if (cart.items.isNotEmpty)
                        TextButton(
                          onPressed: () => cart.clear(),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: cart.items.isEmpty
                      ? const Center(child: Text('Cart is empty'))
                      : ListView.builder(
                          itemCount: cart.items.length,
                          itemBuilder: (_, i) {
                            final item = cart.items[i];
                            return ListTile(
                              title: Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text('${item.quantity} ${item.unit} × ${CurrencyUtils.formatPlain(item.unitPrice)}'),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                                    onPressed: () => cart.updateQty(item.productId, item.quantity - 1),
                                  ),
                                  Text('${item.quantity}'),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline, size: 20),
                                    onPressed: () => cart.updateQty(item.productId, item.quantity + 1),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _row('Subtotal', CurrencyUtils.format(cart.subtotal)),
                      _row('Total', CurrencyUtils.format(cart.total), bold: true),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          onPressed: _checkingOut || cart.items.isEmpty ? null : _checkout,
                          icon: _checkingOut
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                          label: Text(_checkingOut ? 'Processing...' : 'Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String l, String v, {bool bold = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500)),
            Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, fontSize: bold ? 18 : 14)),
          ],
        ),
      );
}
