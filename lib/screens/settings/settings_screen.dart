import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../providers/settings_provider.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/constants/db_constants.dart';
import '../../core/database/database_helper.dart';
import '../../widgets/app_header.dart';
import 'activity_log_screen.dart';
import 'notes_screen.dart';

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
    name.dispose();
    address.dispose();
    phone.dispose();
    footer.dispose();
    super.dispose();
  }

  Future<void> _backup() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final src = File(p.join(dir.path, DbConstants.databaseName));
      if (!await src.exists()) {
        showErrorSnackBar(context, 'Database file not found');
        return;
      }
      final result = await FilePicker.platform.getDirectoryPath();
      if (result == null) return;
      final stamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final dest = p.join(result, 'hardware_store_backup_$stamp.db');
      await src.copy(dest);
      if (mounted) showSuccessSnackBar(context, 'Backup saved');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Backup failed: $e');
    }
  }

  Future<void> _restore() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['db', 'sqlite', 'sqlite3'],
      );
      if (result == null || result.files.single.path == null) return;

      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore database'),
          content: const Text(
            'This will replace your current data with the backup. Continue?',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Restore')),
          ],
        ),
      );
      if (confirm != true) return;

      final backupPath = result.files.single.path!;
      final dir = await getApplicationDocumentsDirectory();
      final dest = p.join(dir.path, DbConstants.databaseName);

      await DatabaseHelper.instance.close();
      await File(backupPath).copy(dest);

      if (mounted) {
        showSuccessSnackBar(context, 'Database restored. Please restart the app.');
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Restore failed: $e');
    }
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
      );
      if (result == null || result.files.single.path == null) return;
      final srcPath = result.files.single.path!;
      final dir = await getApplicationDocumentsDirectory();
      final ext = p.extension(srcPath);
      final destPath = p.join(dir.path, 'shop_logo$ext');
      await File(srcPath).copy(destPath);
      await context.read<SettingsProvider>().setLogoPath(destPath);
      if (mounted) showSuccessSnackBar(context, 'Logo updated');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Logo update failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Column(
      children: [
        const AppHeader(
          title: 'Settings',
          subtitle: 'Shop profile, logo, backup and system tools',
        ),
        Expanded(
          child: ListView(
        padding: const EdgeInsets.fromLTRB(28, 16, 28, 32),
        children: [
          // Shop details
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Shop details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Shop name')),
                  const SizedBox(height: 10),
                  TextField(controller: address, decoration: const InputDecoration(labelText: 'Address')),
                  const SizedBox(height: 10),
                  TextField(controller: phone, decoration: const InputDecoration(labelText: 'Phone')),
                  const SizedBox(height: 10),
                  TextField(controller: footer, decoration: const InputDecoration(labelText: 'Receipt footer')),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      final s = context.read<SettingsProvider>();
                      s.shopName = name.text;
                      s.shopAddress = address.text;
                      s.shopPhone = phone.text;
                      s.receiptFooter = footer.text;
                      await s.save();
                      if (mounted) showSuccessSnackBar(context, 'Settings saved');
                    },
                    child: const Text('Save settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Logo
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sidebar logo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Text(
                    'PNG with transparent background recommended. Only the image is shown.',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: settings.logoPath.isNotEmpty && File(settings.logoPath).existsSync()
                            ? Image.file(File(settings.logoPath), fit: BoxFit.contain)
                            : const Icon(Icons.hardware, size: 28),
                      ),
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        onPressed: _pickLogo,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Choose image'),
                      ),
                      const SizedBox(width: 8),
                      if (settings.logoPath.isNotEmpty)
                        TextButton(
                          onPressed: () async {
                            await context.read<SettingsProvider>().clearLogo();
                            if (mounted) showSuccessSnackBar(context, 'Logo removed');
                          },
                          child: const Text('Remove'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Backup restore
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backup & restore', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _backup,
                        icon: const Icon(Icons.backup_outlined, size: 18),
                        label: const Text('Backup database'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _restore,
                        icon: const Icon(Icons.restore_outlined, size: 18),
                        label: const Text('Restore database'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Default admin: anuja / anuja123',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Activity + Notes
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Activity log'),
                  subtitle: const Text('View system activity'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.note_outlined),
                  title: const Text('Notes'),
                  subtitle: const Text('Personal notes'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotesScreen()),
                  ),
                ),
              ],
            ),
          ),
        ],
          ),
        ),
      ],
    );
  }
}
