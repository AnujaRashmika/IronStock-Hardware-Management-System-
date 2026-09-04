import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/app_header.dart';
import '../../core/utils/validators.dart';
import 'package:flutter/services.dart';
import '../../widgets/confirmation_dialog.dart';
import '../../core/utils/app_snackbar.dart';
import '../../core/utils/currency_utils.dart';
import '../../app/theme.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () => _showAddEditDialog(context),
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () => _showAddEditDialog(context),
      },
      child: Focus(
        autofocus: true,
        child: Column(
          children: [
            const AppHeader(
              title: 'Customers',
              subtitle: 'Manage your store customers',
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: TextField(
                              controller: _searchController,
                              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                              decoration: InputDecoration(
                                hintText: 'Search by name or phone...',
                                prefixIcon: const Icon(Icons.search),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onChanged: (val) {
                                context.read<CustomerProvider>().searchCustomers(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            style: appButtonStyle(color: AppColors.green),
                            label: const Text('Add Customer'),
                            icon: const Icon(Icons.add),
                            onPressed: () => _showAddEditDialog(context),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Consumer<CustomerProvider>(
                        builder: (context, provider, child) {
                          if (provider.isLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (provider.customers.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 50, color: Colors.grey.shade400),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.searchQuery.isEmpty
                                        ? 'No customers added yet.'
                                        : 'No customers found matching "${provider.searchQuery}".',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          }
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: ListView.separated(
                              itemCount: provider.customers.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final customer = provider.customers[index];
                                return InkWell(
                                  onDoubleTap: () => _showAddEditDialog(context, customer: customer),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: CircleAvatar(
                                      backgroundColor: AppColors.tealSoft,
                                      child: Text(
                                        customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                                        style: const TextStyle(color: AppColors.teal, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(
                                      customer.phone ?? 'No phone',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (customer.currentBalance > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(right: 8),
                                            child: Text(
                                              'Due: ${CurrencyUtils.format(customer.currentBalance)}',
                                              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 12),
                                            ),
                                          ),
                                        IconButton(
                                          icon: const Icon(Icons.history, color: AppColors.teal),
                                          tooltip: 'Order History',
                                          onPressed: () => _showHistory(context, customer),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                                          tooltip: 'Edit',
                                          onPressed: () => _showAddEditDialog(context, customer: customer),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          tooltip: 'Delete',
                                          onPressed: () => _confirmDelete(context, customer),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, {Customer? customer}) {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?.name ?? '');
    final phoneController = TextEditingController(text: customer?.phone ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        Future<void> saveCustomer() async {
          if (!formKey.currentState!.validate()) return;
          final newCustomer = Customer(
            id: customer?.id,
            name: nameController.text.trim(),
            phone: phoneController.text.trim(),
            email: customer?.email,
            address: customer?.address,
            customerType: customer?.customerType ?? 'Regular',
            creditLimit: customer?.creditLimit ?? 0,
            openingBalance: customer?.openingBalance ?? 0,
            currentBalance: customer?.currentBalance ?? 0,
            createdAt: customer?.createdAt ?? DateTime.now().toIso8601String(),
          );
          final provider = context.read<CustomerProvider>();
          final success = isEditing
              ? await provider.updateCustomer(newCustomer)
              : await provider.addCustomer(newCustomer);
          if (ctx.mounted) Navigator.pop(ctx);
          if (context.mounted) {
            if (success) {
              showSuccessSnackBar(context, isEditing ? 'Customer updated successfully' : 'Customer added successfully');
            } else {
              showErrorSnackBar(context, 'Operation failed');
            }
          }
        }

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.enter): saveCustomer,
            const SingleActivator(LogicalKeyboardKey.numpadEnter): saveCustomer,
          },
          child: Focus(
            child: Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.5 : 0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                gradient: AppTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isEditing ? Icons.edit_outlined : Icons.person_add_alt_1_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              isEditing ? 'Edit Customer' : 'Add New Customer',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Customer Name *',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Name is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => saveCustomer(),
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            hintText: '07XXXXXXXX',
                            prefixIcon: Icon(Icons.phone_outlined),
                            counterText: '',
                          ),
                          keyboardType: TextInputType.phone,
                          maxLength: 10,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: AppValidators.mobileOptional,
                        ),
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('Cancel'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: saveCustomer,
                                child: Text(isEditing ? 'Update' : 'Save'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Customer customer) async {
    final confirmed = await showConfirmationDialog(
      context,
      title: 'Delete Customer',
      message: 'Are you sure you want to delete "${customer.name}"?',
      confirmText: 'Delete',
      isDestructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!confirmed || customer.id == null) return;
    final success = await context.read<CustomerProvider>().deleteCustomer(customer.id!);
    if (context.mounted) {
      if (success) {
        showSuccessSnackBar(context, 'Customer deleted successfully');
      } else {
        showErrorSnackBar(context, 'Failed to delete customer');
      }
    }
  }

  void _showHistory(BuildContext context, Customer customer) {
    if (customer.id != null) {
      context.read<CustomerProvider>().loadCustomerOrders(customer.id!);
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${customer.name}'s Sales History"),
        content: SizedBox(
          width: 520,
          height: 360,
          child: Consumer<CustomerProvider>(
            builder: (context, provider, _) {
              if (provider.isLoadingOrders) {
                return const Center(child: CircularProgressIndicator());
              }
              if (provider.selectedCustomerOrders.isEmpty) {
                return const Center(child: Text('No sales history found.'));
              }
              double total = 0;
              for (final o in provider.selectedCustomerOrders) {
                total += (o['total'] as num?)?.toDouble() ?? 0;
              }
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.tealSoft, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('Orders: ${provider.selectedCustomerOrders.length}', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('Total: ${CurrencyUtils.format(total)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.teal)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: provider.selectedCustomerOrders.length,
                      separatorBuilder: (_, __) => const Divider(),
                      itemBuilder: (_, i) {
                        final o = provider.selectedCustomerOrders[i];
                        return ListTile(
                          title: Text(o['invoice_no']?.toString() ?? ''),
                          subtitle: Text(o['created_at']?.toString().substring(0, 16) ?? ''),
                          trailing: Text(CurrencyUtils.format(o['total'] ?? 0), style: const TextStyle(fontWeight: FontWeight.w600)),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
