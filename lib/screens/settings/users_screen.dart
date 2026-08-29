import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/user.dart';
import '../../providers/app_provider.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('System User Accounts & Role Permissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showUserModal(context, provider),
                icon: const Icon(Icons.person_add_rounded),
                label: const Text('Add New Staff User'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.users.isEmpty
                  ? const Center(child: Text('No users defined.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.users.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final user = provider.users[index];

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1E293B),
                            child: Icon(Icons.admin_panel_settings, color: Colors.orange.shade400),
                          ),
                          title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Username: ${user.username} | Role: ${user.role} | PIN: ${user.pinOrPassword}'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              user.isActive ? 'Active' : 'Disabled',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: user.isActive ? Colors.green.shade900 : Colors.red.shade900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserModal(BuildContext context, AppProvider provider) {
    final userCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController(text: '1234');
    String role = 'Cashier';

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Staff User Account'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'Username *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Staff Name *', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: role,
                decoration: const InputDecoration(labelText: 'Staff Role', border: OutlineInputBorder()),
                items: ['Admin', 'Cashier', 'Store Keeper', 'Delivery Staff'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (val) {
                  if (val != null) role = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(controller: pinCtrl, decoration: const InputDecoration(labelText: 'PIN / Password', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () {
              if (userCtrl.text.trim().isEmpty || nameCtrl.text.trim().isEmpty) return;
              final user = User(
                id: 'usr-${DateTime.now().millisecondsSinceEpoch}',
                username: userCtrl.text.trim(),
                name: nameCtrl.text.trim(),
                role: role,
                pinOrPassword: pinCtrl.text.trim(),
              );
              provider.saveUser(user);
              Navigator.of(context).pop();
            },
            child: const Text('Create User'),
          ),
        ],
      ),
    );
  }
}
