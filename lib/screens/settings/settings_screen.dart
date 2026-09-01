import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import '../../providers/settings_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/db_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController name, address, phone, footer;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsProvider>();
    name = TextEditingController(text: s.shopName);
    address = TextEditingController(text: s.shopAddress);
    phone = TextEditingController(text: s.shopPhone);
    footer = TextEditingController(text: s.receiptFooter);
  }

  @override
  void dispose() {
    name.dispose(); address.dispose(); phone.dispose(); footer.dispose();
    super.dispose();
  }

  Future<void> _backup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final src = File(p.join(dir.path, DbConstants.databaseName));
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final dest = p.join(result, 'hardware_store_backup_$stamp.db');
      await src.copy(dest);
      if (mounted) showSuccessSnackBar(context, 'Backup saved: $dest');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Backup failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(padding: const EdgeInsets.all(24), children: [
        const Text('Settings', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 20),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Shop Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop Name')),
          const SizedBox(height: 8),
          TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
          const SizedBox(height: 8),
          TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
          const SizedBox(height: 8),
          TextField(controller: footer, decoration: const InputDecoration(labelText: 'Receipt Footer')),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () async {
            final s = context.read<SettingsProvider>();
            s.shopName = name.text;
            s.shopAddress = address.text;
            s.shopPhone = phone.text;
            s.receiptFooter = footer.text;
            await s.save();
            if (mounted) showSuccessSnackBar(context, 'Settings saved');
          }, child: const Text('Save Settings')),
        ]))),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Backup & Restore', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton.icon(onPressed: _backup, icon: const Icon(Icons.backup), label: const Text('Backup Database')),
          const SizedBox(height: 8),
          Text('Default admin: anuja / anuja123', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ]))),
      ]),
    );
  }
}
