import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/product_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/inventory_provider.dart';
import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/purchases/purchases_screen.dart';
import '../screens/returns/returns_screen.dart';
import '../screens/warranty/warranty_screen.dart';
import '../screens/delivery/delivery_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/orders/sales_history_screen.dart';
import 'theme.dart';

class HardwareStoreApp extends StatelessWidget {
  const HardwareStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..load()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()..load()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, theme, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hardware Store Management',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: theme.themeMode,
            home: !auth.initialized
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : auth.isAuthenticated
                    ? const MainLayout()
                    : const LoginScreen(),
          );
        },
      ),
    );
  }
}

class AppPages {
  static const int dashboard = 0;
  static const int pos = 1;
  static const int salesHistory = 2;
  static const int purchases = 3;
  static const int products = 4;
  static const int categories = 5;
  static const int inventory = 6;
  static const int customers = 7;
  static const int suppliers = 8;
  static const int returns = 9;
  static const int warranty = 10;
  static const int delivery = 11;
  static const int expenses = 12;
  static const int reports = 13;
  static const int settings = 14;
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => MainLayoutState();
  static MainLayoutState? of(BuildContext context) =>
      context.findAncestorStateOfType<MainLayoutState>();
}

class MainLayoutState extends State<MainLayout> {
  int _index = 0;

  void navigateTo(int index) => setState(() => _index = index);
  void selectPage(int index) => navigateTo(index);

  Widget _page() {
    switch (_index) {
      case AppPages.dashboard:
        return const DashboardScreen();
      case AppPages.pos:
        return const PosScreen();
      case AppPages.salesHistory:
        return const SalesHistoryScreen();
      case AppPages.purchases:
        return const PurchasesScreen();
      case AppPages.products:
        return const ProductsScreen();
      case AppPages.categories:
        return const CategoriesScreen();
      case AppPages.inventory:
        return const InventoryScreen();
      case AppPages.customers:
        return const CustomersScreen();
      case AppPages.suppliers:
        return const SuppliersScreen();
      case AppPages.returns:
        return const ReturnsScreen();
      case AppPages.warranty:
        return const WarrantyScreen();
      case AppPages.delivery:
        return const DeliveryScreen();
      case AppPages.expenses:
        return const ExpensesScreen();
      case AppPages.reports:
        return const ReportsScreen();
      case AppPages.settings:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(selected: _index, onSelect: navigateTo),
          Expanded(child: _page()),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  const _Sidebar({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsProvider>();
    final auth = context.watch<AuthProvider>();

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
          child: Text(title,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 1.1)),
        );

    Widget item(IconData icon, String title, int index) {
      final active = selected == index;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: Material(
          color: active
              ? AppTheme.primaryColor.withOpacity(isDark ? 0.22 : 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSelect(index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Row(
                children: [
                  Icon(icon,
                      size: 20,
                      color: active
                          ? AppTheme.primaryColor
                          : (isDark ? Colors.white60 : Colors.black54)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                            color: active
                                ? AppTheme.primaryColor
                                : (isDark ? Colors.white70 : Colors.black87))),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      width: 250,
      decoration: BoxDecoration(
        gradient: isDark ? AppTheme.sidebarGradientDark : AppTheme.sidebarGradientLight,
        border: Border(
            right: BorderSide(
                color: isDark ? const Color(0xFF2A3530) : const Color(0xFFE6EAE8))),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.hardware, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settings.shopName.isEmpty ? 'Hardware Store' : settings.shopName,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                section('MAIN'),
                item(Icons.dashboard_outlined, 'Dashboard', AppPages.dashboard),
                item(Icons.point_of_sale_outlined, 'New Sale (POS)', AppPages.pos),
                item(Icons.receipt_long_outlined, 'Sales History', AppPages.salesHistory),
                section('MANAGEMENT'),
                item(Icons.shopping_cart_outlined, 'Purchases', AppPages.purchases),
                item(Icons.inventory_2_outlined, 'Products', AppPages.products),
                item(Icons.category_outlined, 'Categories', AppPages.categories),
                item(Icons.warehouse_outlined, 'Inventory', AppPages.inventory),
                item(Icons.people_outline, 'Customers', AppPages.customers),
                item(Icons.local_shipping_outlined, 'Suppliers', AppPages.suppliers),
                section('OPERATIONS'),
                item(Icons.assignment_return_outlined, 'Returns & Refunds', AppPages.returns),
                item(Icons.verified_outlined, 'Warranty', AppPages.warranty),
                item(Icons.local_shipping, 'Delivery', AppPages.delivery),
                item(Icons.payments_outlined, 'Expenses', AppPages.expenses),
                section('SYSTEM'),
                item(Icons.bar_chart_outlined, 'Reports', AppPages.reports),
                item(Icons.settings_outlined, 'Settings', AppPages.settings),
              ],
            ),
          ),
          // Theme + user
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                ListTile(
                  dense: true,
                  leading: Icon(isDark ? Icons.light_mode : Icons.dark_mode, size: 20),
                  title: Text(isDark ? 'Light Mode' : 'Dark Mode', style: const TextStyle(fontSize: 13)),
                  onTap: () => context.read<ThemeProvider>().toggle(),
                ),
                ListTile(
                  dense: true,
                  leading: const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                  title: Text(auth.currentUser?.fullName ?? 'User', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(auth.currentUser?.role ?? '', style: const TextStyle(fontSize: 11)),
                  trailing: IconButton(
                    icon: const Icon(Icons.logout, size: 18),
                    onPressed: () => auth.logout(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
