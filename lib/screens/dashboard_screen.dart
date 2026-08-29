import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final todaySales = provider.todaySalesTotal;
    final todayPurchases = provider.todayPurchasesTotal;
    final todayProfit = provider.todayProfitTotal;
    final customerCredit = provider.totalCustomerOutstanding;

    final lowStockCount = provider.lowStockProducts.length;
    final pendingDeliveriesCount = provider.pendingDeliveries.length;
    final pendingReturnsCount = provider.salesReturns.where((r) => r.refundMethod == 'Pending').length;
    final warrantyClaimsCount = provider.activeWarrantyClaims.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: KPI Financial Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: "Today's Sales",
                  amount: provider.formatCurrency(todaySales),
                  icon: Icons.payments_rounded,
                  color: Colors.blue,
                  subtitle: '${provider.sales.where((s) => _isToday(s.date)).length} transactions today',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: "Today's Purchases",
                  amount: provider.formatCurrency(todayPurchases),
                  icon: Icons.shopping_bag_rounded,
                  color: Colors.orange,
                  subtitle: '${provider.purchases.where((p) => _isToday(p.date)).length} purchases today',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: "Today's Net Profit",
                  amount: provider.formatCurrency(todayProfit),
                  icon: Icons.trending_up_rounded,
                  color: todayProfit >= 0 ? Colors.green : Colors.red,
                  subtitle: 'Sales Margin - Expenses',
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  title: 'Pending Customer Credit',
                  amount: provider.formatCurrency(customerCredit),
                  icon: Icons.account_balance_wallet_rounded,
                  color: Colors.purple,
                  subtitle: 'Total outstanding receivable',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Row 2: Secondary Alert Stat Cards
          Row(
            children: [
              Expanded(
                child: _buildAlertCard(
                  title: 'Low Stock Items',
                  count: '$lowStockCount Items',
                  icon: Icons.warning_amber_rounded,
                  color: Colors.amber.shade800,
                  onTap: () => provider.setScreen('low_stock'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAlertCard(
                  title: 'Pending Deliveries',
                  count: '$pendingDeliveriesCount',
                  icon: Icons.local_shipping_rounded,
                  color: Colors.blue.shade700,
                  onTap: () => provider.setScreen('delivery'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAlertCard(
                  title: 'Sales Returns',
                  count: '$pendingReturnsCount',
                  icon: Icons.assignment_return_rounded,
                  color: Colors.deepOrange,
                  onTap: () => provider.setScreen('sales_returns'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildAlertCard(
                  title: 'Warranty Claims',
                  count: '$warrantyClaimsCount',
                  icon: Icons.verified_user_rounded,
                  color: Colors.teal,
                  onTap: () => provider.setScreen('warranty'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Row 3: Main Tables & Summary Grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left Column: Recent Sales & Low Stock List
              Expanded(
                flex: 3,
                child: Column(
                  children: [
                    // Recent Sales Table
                    _buildSectionContainer(
                      title: 'Recent Sales Transactions',
                      actionText: 'View All Sales',
                      onActionTap: () => provider.setScreen('sales_history'),
                      child: provider.sales.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No sales recorded yet.'),
                            )
                          : Table(
                              columnWidths: const {
                                0: FlexColumnWidth(1.2),
                                1: FlexColumnWidth(2),
                                2: FlexColumnWidth(1.2),
                                3: FlexColumnWidth(1.5),
                                4: FlexColumnWidth(1.2),
                              },
                              children: [
                                const TableRow(
                                  decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey))),
                                  children: [
                                    Padding(padding: EdgeInsets.all(8), child: Text('Invoice #', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                                    Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  ],
                                ),
                                ...provider.sales.take(5).map((sale) => TableRow(
                                      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
                                      children: [
                                        Padding(padding: const EdgeInsets.all(8), child: Text(sale.invoiceNo, style: const TextStyle(fontWeight: FontWeight.w500))),
                                        Padding(padding: const EdgeInsets.all(8), child: Text(sale.customerName)),
                                        Padding(padding: const EdgeInsets.all(8), child: Text(sale.primaryPaymentMethod)),
                                        Padding(padding: const EdgeInsets.all(8), child: Text(provider.formatCurrency(sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold))),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: sale.paymentStatus == 'Paid'
                                                  ? Colors.green.shade100
                                                  : (sale.paymentStatus == 'Partial' ? Colors.amber.shade100 : Colors.red.shade100),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              sale.paymentStatus,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: sale.paymentStatus == 'Paid'
                                                    ? Colors.green.shade900
                                                    : (sale.paymentStatus == 'Partial' ? Colors.amber.shade900 : Colors.red.shade900),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                    ),

                    const SizedBox(height: 24),

                    // Low Stock Alert Table
                    _buildSectionContainer(
                      title: 'Low Stock Items Warning',
                      actionText: 'Manage Inventory',
                      onActionTap: () => provider.setScreen('low_stock'),
                      child: provider.lowStockProducts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('All products have adequate stock level.'),
                            )
                          : Column(
                              children: provider.lowStockProducts.map((prod) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.warning_amber_rounded, color: Colors.amber),
                                title: Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text('Code: ${prod.code} | Category: ${prod.category} | Location: ${prod.rackLocation}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${prod.currentStock.toStringAsFixed(0)} ${prod.unit}',
                                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Reorder: ${prod.reorderLevel.toStringAsFixed(0)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              )).toList(),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 24),

              // Right Column: Shortcuts, Top Selling Products, Deliveries Overview
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    // Quick POS Shortcut Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.point_of_sale_rounded, color: Colors.orange, size: 28),
                              SizedBox(width: 12),
                              Text(
                                'POS Quick Checkout',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Start a new customer billing session quickly.',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 45),
                            ),
                            onPressed: () => provider.setScreen('pos'),
                            icon: const Icon(Icons.add_shopping_cart_rounded),
                            label: const Text('Open POS Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Top Selling Products Widget
                    _buildSectionContainer(
                      title: 'Top Inventory Items',
                      child: Column(
                        children: provider.products.take(5).map((p) => ListTile(
                          dense: true,
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text(
                              p.unit.substring(0, 1).toUpperCase(),
                              style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('Price: ${provider.formatCurrency(p.sellingPrice)} / ${p.unit}'),
                          trailing: Text(
                            '${p.currentStock.toStringAsFixed(0)} ${p.unit}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )).toList(),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Pending Deliveries Overview
                    _buildSectionContainer(
                      title: 'Pending Deliveries Overview',
                      actionText: 'Track All',
                      onActionTap: () => provider.setScreen('delivery'),
                      child: provider.pendingDeliveries.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No active pending deliveries.'),
                            )
                          : Column(
                              children: provider.pendingDeliveries.take(3).map((d) => ListTile(
                                dense: true,
                                leading: const Icon(Icons.local_shipping, color: Colors.blue),
                                title: Text(d.customerName),
                                subtitle: Text('Invoice #${d.invoiceNo} | ${d.address}'),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    d.status,
                                    style: TextStyle(fontSize: 10, color: Colors.blue.shade900, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
                Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    String? actionText,
    VoidCallback? onActionTap,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                if (actionText != null && onActionTap != null)
                  InkWell(
                    onTap: onActionTap,
                    child: Text(actionText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          child,
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }
}
