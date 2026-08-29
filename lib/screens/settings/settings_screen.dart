import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shop_settings.dart';
import '../../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _invPrefixCtrl;
  late TextEditingController _receiptPrefixCtrl;
  late TextEditingController _thresholdCtrl;

  @override
  void initState() {
    super.initState();
    final settings = Provider.of<AppProvider>(context, listen: false).shopSettings;
    _nameCtrl = TextEditingController(text: settings.shopName);
    _addressCtrl = TextEditingController(text: settings.address);
    _phoneCtrl = TextEditingController(text: settings.phone);
    _emailCtrl = TextEditingController(text: settings.email);
    _currencyCtrl = TextEditingController(text: settings.currency);
    _invPrefixCtrl = TextEditingController(text: settings.invoicePrefix);
    _receiptPrefixCtrl = TextEditingController(text: settings.receiptPrefix);
    _thresholdCtrl = TextEditingController(text: settings.lowStockThreshold.toStringAsFixed(0));
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Shop Details & Invoice Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Divider(height: 24),

              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Shop Business Name', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Store Address', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Contact Numbers', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Business Email', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextField(controller: _currencyCtrl, decoration: const InputDecoration(labelText: 'Currency Symbol', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _invPrefixCtrl, decoration: const InputDecoration(labelText: 'Invoice Number Prefix', border: OutlineInputBorder()))),
                  const SizedBox(width: 12),
                  Expanded(child: TextField(controller: _receiptPrefixCtrl, decoration: const InputDecoration(labelText: 'Receipt Prefix', border: OutlineInputBorder()))),
                ],
              ),
              const SizedBox(height: 12),
              TextField(controller: _thresholdCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Default Low Stock Alert Threshold', border: OutlineInputBorder())),

              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                ),
                onPressed: () {
                  final newSettings = ShopSettings(
                    shopName: _nameCtrl.text.trim(),
                    address: _addressCtrl.text.trim(),
                    phone: _phoneCtrl.text.trim(),
                    email: _emailCtrl.text.trim(),
                    currency: _currencyCtrl.text.trim(),
                    invoicePrefix: _invPrefixCtrl.text.trim(),
                    receiptPrefix: _receiptPrefixCtrl.text.trim(),
                    lowStockThreshold: double.tryParse(_thresholdCtrl.text) ?? 20,
                  );

                  provider.updateSettings(newSettings);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Shop settings updated successfully!')),
                  );
                },
                icon: const Icon(Icons.save),
                label: const Text('Save Shop Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
