import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/inventory_provider.dart';
import '../providers/product_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/theme_provider.dart';

import '../screens/auth/login_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/pos/pos_screen.dart';
import '../screens/products/products_screen.dart';
import '../screens/categories/categories_screen.dart';
import '../screens/orders/sales_history_screen.dart';
import '../screens/customers/customers_screen.dart';
import '../screens/inventory/inventory_screen.dart';
import '../screens/purchases/purchases_screen.dart';
import '../screens/suppliers/suppliers_screen.dart';
import '../screens/returns/returns_screen.dart';
import '../screens/warranty/warranty_screen.dart';
import '../screens/delivery/delivery_screen.dart';
import '../screens/expenses/expenses_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/settings/settings_screen.dart';

import '../widgets/app_sidebar.dart';
import 'theme.dart';

class HardwareStoreApp extends StatelessWidget {
  const HardwareStoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => ProductProvider()..load()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => InventoryProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()..load()),
      ],
      child: Consumer2<ThemeProvider, AuthProvider>(
        builder: (context, theme, auth, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Hardware Store',
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

/// Sidebar / navigation page indices
class AppPages {
  static const int dashboard = 0;
  static const int pos = 1;
  static const int salesHistory = 2;
  static const int products = 3;
  static const int categories = 4;
  static const int inventory = 5;
  static const int purchases = 6;
  static const int suppliers = 7;
  static const int customers = 8;
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

  static MainLayoutState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainLayoutState>();
  }
}

class MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),       // 0
    PosScreen(),             // 1
    SalesHistoryScreen(),    // 2
    ProductsScreen(),        // 3
    CategoriesScreen(),      // 4
    InventoryScreen(),       // 5
    PurchasesScreen(),       // 6
    SuppliersScreen(),       // 7
    CustomersScreen(),       // 8
    ReturnsScreen(),         // 9
    WarrantyScreen(),        // 10
    DeliveryScreen(),        // 11
    ExpensesScreen(),        // 12
    ReportsScreen(),         // 13
    SettingsScreen(),        // 14
  ];

  void navigateTo(int index) => selectPage(index);

  void selectPage(int index) {
    if (index < 0 || index >= _screens.length) return;
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: selectPage,
          ),
          Expanded(child: _screens[_selectedIndex]),
        ],
      ),
    );
  }
}
