import 'package:flutter/material.dart';
import '../../core/utils/activity_logger.dart';
import '../../app/theme.dart';

/// Full-page activity log with period + category filters.
/// Opened from Settings → View Log. Back returns to Settings.
class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  String _period = 'today';
  String _category = 'all';
  bool _loading = true;
  List<Map<String, dynamic>> _logs = [];

  static const List<Map<String, String>> _periods = [
    {'id': 'today', 'label': 'Today'},
    {'id': 'yesterday', 'label': 'Yesterday'},
    {'id': 'last_week', 'label': 'Last week'},
    {'id': 'this_month', 'label': 'This month'},
    {'id': 'all', 'label': 'All'},
  ];

  static const _categoryIds = ['all', 'login', 'orders', 'changes', 'delete'];
  static const _categoryLabels = ['All', 'Login', 'Orders', 'Changes', 'Delete'];
  static const _categoryIcons = [
    Icons.list_alt,
    Icons.login,
    Icons.receipt_long_outlined,
    Icons.edit_outlined,
    Icons.delete_outline,
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final logs = await ActivityLogger.query(
      period: _period,
      category: _category,
      limit: 500,
    );
    if (!mounted) return;
    setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  void _setPeriod(String value) {
    if (_period == value) return;
    setState(() => _period = value);
    _load();
  }

  void _setCategory(String value) {
    if (_category == value) return;
    setState(() => _category = value);
    _load();
  }

  IconData _iconFor(String action, String entityType) {
    final a = action.toLowerCase();
    final e = entityType.toLowerCase();
    if (a.contains('login') || e == 'auth') return Icons.login;
    if (a.contains('logout')) return Icons.logout;
    if (a.contains('delete') || a.contains('deactivate')) {
      return Icons.delete_outline;
    }
    if (e == 'order' || a.contains('checkout') || a.contains('order')) {
      return Icons.receipt_long_outlined;
    }
    if (a.contains('stock')) return Icons.inventory_2_outlined;
    if (a.contains('create') || a.contains('add')) return Icons.add_circle_outline;
    if (a.contains('update') || a.contains('edit') || a.contains('change')) {
      return Icons.edit_outlined;
    }
    return Icons.history;
  }

  Color _colorFor(String action) {
    final a = action.toLowerCase();
    if (a.contains('delete') || a.contains('deactivate')) {
      return AppColors.red;
    }
    if (a.contains('login')) return const Color(0xFF009966);
    if (a.contains('checkout') || a.contains('order')) {
      return AppColors.green;
    }
    if (a.contains('stock') || a.contains('inventory')) {
      return AppColors.teal;
    }
    return AppColors.orange;
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final d = DateTime.parse(iso);
      final hh = d.hour.toString().padLeft(2, '0');
      final mm = d.minute.toString().padLeft(2, '0');
      final ss = d.second.toString().padLeft(2, '0');
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}  $hh:$mm:$ss';
    } catch (_) {
      return iso.length > 19 ? iso.substring(0, 19) : iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Activity Log'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Categories (left) | Periods (right)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(_categoryIds.length, (i) {
                      final id = _categoryIds[i];
                      final selected = _category == id;
                      return FilterChip(
                        avatar: Icon(
                          _categoryIcons[i],
                          size: 18,
                          color: selected
                              ? const Color(0xFF009966)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                        label: Text(_categoryLabels[i]),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => _setCategory(id),
                        selectedColor: isDark
                            ? const Color(0xFF009966).withOpacity(0.28)
                            : const Color(0xFF009966).withOpacity(0.16),
                        backgroundColor: isDark
                            ? const Color(0xFF242424)
                            : const Color(0xFFE4E6EB),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF009966)
                              : theme.dividerColor,
                        ),
                        labelStyle: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? (isDark
                                  ? const Color(0xFF3DC08D)
                                  : const Color(0xFF00754D))
                              : theme.colorScheme.onSurface,
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: _periods.map((p) {
                      final selected = _period == p['id'];
                      return ChoiceChip(
                        label: Text(p['label']!),
                        selected: selected,
                        showCheckmark: false,
                        onSelected: (_) => _setPeriod(p['id']!),
                        selectedColor: isDark
                            ? const Color(0xFF009966).withOpacity(0.28)
                            : const Color(0xFF009966).withOpacity(0.16),
                        backgroundColor: isDark
                            ? const Color(0xFF242424)
                            : const Color(0xFFE4E6EB),
                        side: BorderSide(
                          color: selected
                              ? const Color(0xFF009966)
                              : theme.dividerColor,
                        ),
                        labelStyle: TextStyle(
                          fontWeight:
                              selected ? FontWeight.w600 : FontWeight.w500,
                          color: selected
                              ? (isDark
                                  ? const Color(0xFF3DC08D)
                                  : const Color(0xFF00754D))
                              : theme.colorScheme.onSurface,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              _loading ? 'Loading…' : '${_logs.length} record(s)',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _logs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 48,
                              color: theme.colorScheme.onSurface.withOpacity(0.35),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No activity for this filter',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: _logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final l = _logs[i];
                          final action = '${l['action'] ?? ''}';
                          final entity = '${l['entity_type'] ?? ''}';
                          final details = '${l['details'] ?? ''}';
                          final color = _colorFor(action);

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF1A1A1A)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.dividerColor),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.12),
                                child: Icon(
                                  _iconFor(action, entity),
                                  color: color,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                '$action · $entity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: details.isEmpty
                                  ? null
                                  : Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        details,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: theme.colorScheme.onSurface
                                              .withOpacity(0.65),
                                        ),
                                      ),
                                    ),
                              trailing: Text(
                                _formatTime(l['created_at'] as String?),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withOpacity(0.55),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
