import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';
import 'dashboard_screen.dart';
import 'sales/pos_screen.dart';
import 'sales/sales_history_screen.dart';
import 'sales/quotations_screen.dart';
import 'sales/held_sales_screen.dart';
import 'purchases/new_purchase_screen.dart';
import 'purchases/purchase_history_screen.dart';
import 'purchases/suppliers_screen.dart';
import 'inventory/products_screen.dart';
import 'inventory/categories_screen.dart';
import 'inventory/stock_adjustment_screen.dart';
import 'inventory/low_stock_screen.dart';
import 'customers/customers_screen.dart';
import 'customers/customer_credit_screen.dart';
import 'returns/sales_returns_screen.dart';
import 'returns/refunds_screen.dart';
import 'warranty/warranty_screen.dart';
import 'delivery/delivery_screen.dart';
import 'expenses/expenses_screen.dart';
import 'day_closing/day_closing_screen.dart';
import 'reports/reports_screen.dart';
import 'settings/settings_screen.dart';
import 'settings/users_screen.dart';
import 'settings/audit_log_screen.dart';
import 'settings/backup_restore_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'Loading Hardware Shop Management System...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Row(
        children: [
          // Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: _isSidebarCollapsed ? 70 : 250,
            decoration: const BoxDecoration(
              color: Color(0xFF1E293B),
            ),
            child: Column(
              children: [
                // Header / Logo
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  color: const Color(0xFF0F172A),
                  child: Row(
                    children: [
                      const Icon(Icons.build_circle_rounded, color: Colors.orange, size: 32),
                      if (!_isSidebarCollapsed) ...[
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'IRON STOCK',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'Hardware & Building',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: Colors.white10),

                // Navigation Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildNavItem(
                        context,
                        id: 'dashboard',
                        title: 'Dashboard',
                        icon: Icons.dashboard_rounded,
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Sales & POS',
                        icon: Icons.point_of_sale_rounded,
                        items: [
                          {'id': 'pos', 'title': 'New Sale (POS)', 'icon': Icons.add_shopping_cart_rounded},
                          {'id': 'sales_history', 'title': 'Sales History', 'icon': Icons.receipt_long_rounded},
                          {'id': 'quotations', 'title': 'Quotations', 'icon': Icons.request_quote_rounded},
                          {'id': 'held_sales', 'title': 'Held Sales', 'icon': Icons.pause_circle_outline_rounded},
                        ],
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Purchases',
                        icon: Icons.shopping_bag_rounded,
                        items: [
                          {'id': 'new_purchase', 'title': 'New Purchase', 'icon': Icons.add_business_rounded},
                          {'id': 'purchase_history', 'title': 'Purchase History', 'icon': Icons.history_edu_rounded},
                          {'id': 'suppliers', 'title': 'Suppliers', 'icon': Icons.local_shipping_rounded},
                        ],
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Inventory',
                        icon: Icons.inventory_2_rounded,
                        items: [
                          {'id': 'products', 'title': 'Products', 'icon': Icons.category_rounded},
                          {'id': 'categories', 'title': 'Categories', 'icon': Icons.grid_view_rounded},
                          {'id': 'stock_adjustment', 'title': 'Stock Adjustment', 'icon': Icons.tune_rounded},
                          {'id': 'low_stock', 'title': 'Low Stock Alert', 'icon': Icons.warning_amber_rounded},
                        ],
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Customers',
                        icon: Icons.people_alt_rounded,
                        items: [
                          {'id': 'customers', 'title': 'Customers Directory', 'icon': Icons.person_rounded},
                          {'id': 'customer_credit', 'title': 'Customer Credit', 'icon': Icons.account_balance_wallet_rounded},
                        ],
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Returns & Refunds',
                        icon: Icons.assignment_return_rounded,
                        items: [
                          {'id': 'sales_returns', 'title': 'Sales Returns', 'icon': Icons.keyboard_return_rounded},
                          {'id': 'refunds', 'title': 'Refunds History', 'icon': Icons.money_off_rounded},
                        ],
                      ),
                      _buildNavItem(
                        context,
                        id: 'warranty',
                        title: 'Warranty Claims',
                        icon: Icons.verified_user_rounded,
                        badgeCount: provider.activeWarrantyClaims.length,
                      ),
                      _buildNavItem(
                        context,
                        id: 'delivery',
                        title: 'Deliveries',
                        icon: Icons.fire_truck_rounded,
                        badgeCount: provider.pendingDeliveries.length,
                      ),
                      _buildNavItem(
                        context,
                        id: 'expenses',
                        title: 'Expenses',
                        icon: Icons.account_balance_rounded,
                      ),
                      _buildNavItem(
                        context,
                        id: 'day_closing',
                        title: 'Cash Closing',
                        icon: Icons.lock_clock_rounded,
                      ),
                      _buildNavItem(
                        context,
                        id: 'reports',
                        title: 'Reports',
                        icon: Icons.analytics_rounded,
                      ),
                      _buildExpandableNavGroup(
                        context,
                        title: 'Settings',
                        icon: Icons.settings_rounded,
                        items: [
                          {'id': 'settings', 'title': 'Shop Details', 'icon': Icons.store_rounded},
                          {'id': 'users', 'title': 'Users & Roles', 'icon': Icons.admin_panel_settings_rounded},
                          {'id': 'audit_log', 'title': 'Audit Log', 'icon': Icons.history_rounded},
                          {'id': 'backup_restore', 'title': 'Backup & Restore', 'icon': Icons.backup_rounded},
                        ],
                      ),
                    ],
                  ),
                ),

                // Collapse Toggle Footer
                InkWell(
                  onTap: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.white.withValues(alpha: 0.05),
                    child: Row(
                      mainAxisAlignment:
                          _isSidebarCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                      children: [
                        Icon(
                          _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                          color: Colors.white70,
                        ),
                        if (!_isSidebarCollapsed) ...[
                          const SizedBox(width: 12),
                          const Text(
                            'Collapse Menu',
                            style: TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Main Screen Workspace
          Expanded(
            child: Column(
              children: [
                // Top Header Bar
                Container(
                  height: 65,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _getScreenTitle(provider.currentScreen),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 24),

                      // Quick Alert Badges
                      if (provider.lowStockProducts.isNotEmpty)
                        GestureDetector(
                          onTap: () => provider.setScreen('low_stock'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber.shade300),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber),
                                const SizedBox(width: 6),
                                Text(
                                  'Low Stock: ${provider.lowStockProducts.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber.shade900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      const Spacer(),

                      // Today Date
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEE, dd MMM yyyy').format(DateTime.now()),
                            style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 24),

                      // User Pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 14,
                              backgroundColor: Color(0xFF1E293B),
                              child: Icon(Icons.person, size: 16, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  provider.currentUser?.name ?? 'Admin User',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                Text(
                                  provider.currentUser?.role ?? 'Manager',
                                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Content Body
                Expanded(
                  child: Container(
                    color: Colors.grey.shade100,
                    child: _buildCurrentScreen(provider.currentScreen),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required String id,
    required String title,
    required IconData icon,
    int badgeCount = 0,
  }) {
    final provider = Provider.of<AppProvider>(context);
    final isSelected = provider.currentScreen == id;

    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: Colors.orange.withValues(alpha: 0.15),
      leading: Icon(
        icon,
        color: isSelected ? Colors.orange : Colors.grey.shade400,
        size: 20,
      ),
      title: _isSidebarCollapsed
          ? null
          : Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.orange : Colors.grey.shade300,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
      trailing: !_isSidebarCollapsed && badgeCount > 0
          ? Container(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            )
          : null,
      onTap: () => provider.setScreen(id),
    );
  }

  Widget _buildExpandableNavGroup(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> items,
  }) {
    final provider = Provider.of<AppProvider>(context);
    final isChildSelected = items.any((i) => i['id'] == provider.currentScreen);

    if (_isSidebarCollapsed) {
      return PopupMenuButton<String>(
        tooltip: title,
        icon: Icon(icon, color: isChildSelected ? Colors.orange : Colors.grey.shade400, size: 20),
        onSelected: (id) => provider.setScreen(id),
        itemBuilder: (context) => items
            .map((item) => PopupMenuItem<String>(
                  value: item['id'] as String,
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 8),
                      Text(item['title'] as String),
                    ],
                  ),
                ))
            .toList(),
      );
    }

    return ExpansionTile(
      initiallyExpanded: isChildSelected,
      leading: Icon(icon, color: isChildSelected ? Colors.orange : Colors.grey.shade400, size: 20),
      title: Text(
        title,
        style: TextStyle(
          color: isChildSelected ? Colors.orange : Colors.grey.shade300,
          fontWeight: isChildSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
      childrenPadding: const EdgeInsets.only(left: 16),
      children: items
          .map((item) => ListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(
                  item['icon'] as IconData,
                  size: 16,
                  color: provider.currentScreen == item['id'] ? Colors.orange : Colors.grey.shade500,
                ),
                title: Text(
                  item['title'] as String,
                  style: TextStyle(
                    color: provider.currentScreen == item['id'] ? Colors.orange : Colors.grey.shade400,
                    fontSize: 12,
                    fontWeight: provider.currentScreen == item['id'] ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () => provider.setScreen(item['id'] as String),
              ))
          .toList(),
    );
  }

  String _getScreenTitle(String screenId) {
    switch (screenId) {
      case 'dashboard':
        return 'Dashboard Overview';
      case 'pos':
        return 'Point of Sale (POS)';
      case 'sales_history':
        return 'Sales History & Invoices';
      case 'quotations':
        return 'Quotations & Estimates';
      case 'held_sales':
        return 'Held Sales Cart Sessions';
      case 'new_purchase':
        return 'New Purchase Entry';
      case 'purchase_history':
        return 'Purchase History';
      case 'suppliers':
        return 'Suppliers Management';
      case 'products':
        return 'Products & Inventory';
      case 'categories':
        return 'Product Categories';
      case 'stock_adjustment':
        return 'Stock Adjustment';
      case 'low_stock':
        return 'Low Stock Alerts';
      case 'customers':
        return 'Customers Directory';
      case 'customer_credit':
        return 'Customer Credit & Payments';
      case 'sales_returns':
        return 'Sales Returns';
      case 'refunds':
        return 'Refunds History';
      case 'warranty':
        return 'Warranty Claims';
      case 'delivery':
        return 'Delivery Management';
      case 'expenses':
        return 'Expenses Tracker';
      case 'day_closing':
        return 'Cashier Shift Day-End Closing';
      case 'reports':
        return 'Business Reports & Analytics';
      case 'settings':
        return 'Shop Settings';
      case 'users':
        return 'User Accounts & Roles';
      case 'audit_log':
        return 'System Audit Log';
      case 'backup_restore':
        return 'Backup & Restore';
      default:
        return 'Hardware Shop System';
    }
  }

  Widget _buildCurrentScreen(String screenId) {
    switch (screenId) {
      case 'dashboard':
        return const DashboardScreen();
      case 'pos':
        return const PosScreen();
      case 'sales_history':
        return const SalesHistoryScreen();
      case 'quotations':
        return const QuotationsScreen();
      case 'held_sales':
        return const HeldSalesScreen();
      case 'new_purchase':
        return const NewPurchaseScreen();
      case 'purchase_history':
        return const PurchaseHistoryScreen();
      case 'suppliers':
        return const SuppliersScreen();
      case 'products':
        return const ProductsScreen();
      case 'categories':
        return const CategoriesScreen();
      case 'stock_adjustment':
        return const StockAdjustmentScreen();
      case 'low_stock':
        return const LowStockScreen();
      case 'customers':
        return const CustomersScreen();
      case 'customer_credit':
        return const CustomerCreditScreen();
      case 'sales_returns':
        return const SalesReturnsScreen();
      case 'refunds':
        return const RefundsScreen();
      case 'warranty':
        return const WarrantyScreen();
      case 'delivery':
        return const DeliveryScreen();
      case 'expenses':
        return const ExpensesScreen();
      case 'day_closing':
        return const DayClosingScreen();
      case 'reports':
        return const ReportsScreen();
      case 'settings':
        return const SettingsScreen();
      case 'users':
        return const UsersScreen();
      case 'audit_log':
        return const AuditLogScreen();
      case 'backup_restore':
        return const BackupRestoreScreen();
      default:
        return const DashboardScreen();
    }
  }
}
