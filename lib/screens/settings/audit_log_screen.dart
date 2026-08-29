import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('System Audit Trail & Operations Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.auditLogs.isEmpty
                  ? const Center(child: Text('No audit logs recorded.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.auditLogs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final log = provider.auditLogs[index];

                        return ListTile(
                          dense: true,
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF0F172A),
                            child: Icon(Icons.security, color: Colors.orange, size: 16),
                          ),
                          title: Row(
                            children: [
                              Text(log.action, style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text('by ${log.username}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                            ],
                          ),
                          subtitle: Text('${log.details} | Ref: ${log.reference}'),
                          trailing: Text(DateFormat('dd MMM yyyy HH:mm').format(log.date), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
