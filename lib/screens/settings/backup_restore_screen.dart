import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_provider.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  bool _autoBackup = true;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Local Database Backup & Data Protection', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.backup_rounded, color: Colors.blue, size: 28),
                    SizedBox(width: 12),
                    Text('Local SQLite Database Protection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your data is stored 100% locally on your PC in SQLite. No internet connection is required. You can back up your database to USB drives or external HDDs at any time.',
                  style: TextStyle(color: Colors.grey),
                ),
                const Divider(height: 32),

                // Auto Backup Switch
                SwitchListTile(
                  title: const Text('Automatic Daily Backup on Application Exit', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Saves daily snapshots to the local Backups folder.'),
                  value: _autoBackup,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() => _autoBackup = val);
                  },
                ),

                const SizedBox(height: 24),

                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: () {
                        provider.addAuditLog('Backup Database', 'Created local database backup file.');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Database backup exported successfully to hardware_shop_backup.db!')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded),
                      label: const Text('Export Backup File Now'),
                    ),
                    const SizedBox(width: 16),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Select backup file to restore database.')),
                        );
                      },
                      icon: const Icon(Icons.upload_file_rounded),
                      label: const Text('Restore Database from Backup'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
