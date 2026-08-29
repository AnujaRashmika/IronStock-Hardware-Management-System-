import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/app_provider.dart';
import 'screens/main_layout.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HardwareShopApp());
}

class HardwareShopApp extends StatelessWidget {
  const HardwareShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppProvider>(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: 'Hardware Shop Management System',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.orange,
            primary: Colors.orange,
            secondary: const Color(0xFF1E293B),
          ),
          scaffoldBackgroundColor: Colors.grey.shade100,
        ),
        home: const MainLayout(),
      ),
    );
  }
}
