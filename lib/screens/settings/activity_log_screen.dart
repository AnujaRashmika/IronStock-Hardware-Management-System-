import 'package:flutter/material.dart';
import '../../core/database/database_helper.dart';
import '../../core/constants/db_constants.dart';
import '../../widgets/page_header.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});
  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  List<Map<String, dynamic>> logs = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final db = await DatabaseHelper.instance.database;
    logs = await db.query(DbConstants.activityLog, orderBy: 'created_at DESC', limit: 200);
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity log')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : logs.isEmpty
                ? const Center(child: Text('No activity yet'))
                : Card(
                    child: ListView.separated(
                      itemCount: logs.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final l = logs[i];
                        return ListTile(
                          dense: true,
                          title: Text(l['action']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(
                            '${l['username'] ?? ''} • ${l['entity_type'] ?? ''} • ${l['details'] ?? ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Text(
                            (l['created_at']?.toString() ?? '').length > 16
                                ? l['created_at'].toString().substring(0, 16)
                                : l['created_at']?.toString() ?? '',
                            style: const TextStyle(fontSize: 11),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }
}
