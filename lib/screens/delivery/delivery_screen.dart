import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../models/customer.dart';
import '../../providers/app_provider.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  String _selectedStatus = 'All';

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    final filteredDeliveries = provider.deliveries.where((d) {
      if (_selectedStatus == 'All') return true;
      return d.status == _selectedStatus;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Delivery Management & Dispatch (${filteredDeliveries.length} Deliveries)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: () => _showNewDeliveryModal(context, provider),
                icon: const Icon(Icons.add_location_alt_rounded),
                label: const Text('Create New Delivery Note'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Status Chips
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ['All', 'Pending', 'Scheduled', 'Out for Delivery', 'Delivered', 'Failed']
                  .map((status) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(status),
                          selected: _selectedStatus == status,
                          selectedColor: Colors.blue.shade100,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedStatus = status);
                          },
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: filteredDeliveries.isEmpty
                  ? const Center(child: Text('No delivery records found.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredDeliveries.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final del = filteredDeliveries[index];
                        final isDelivered = del.status == 'Delivered';

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDelivered ? Colors.green.shade100 : Colors.blue.shade100,
                            child: Icon(Icons.local_shipping, color: isDelivered ? Colors.green.shade900 : Colors.blue.shade900),
                          ),
                          title: Row(
                            children: [
                              Text('${del.deliveryNo} - ${del.customerName}', style: const TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isDelivered ? Colors.green.shade100 : Colors.blue.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  del.status,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDelivered ? Colors.green.shade900 : Colors.blue.shade900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Text(
                              'Invoice #: ${del.invoiceNo} | Address: ${del.address} | Driver: ${del.driverName.isNotEmpty ? del.driverName : "Unassigned"} (${del.vehicleNo})\nDelivery Date: ${DateFormat('dd MMM yyyy').format(del.deliveryDate)} | Delivery Charge: Rs. ${del.deliveryCharge.toStringAsFixed(2)}'),
                          isThreeLine: true,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isDelivered)
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                  onPressed: () => _showCompleteDeliveryModal(context, provider, del),
                                  icon: const Icon(Icons.check, size: 16),
                                  label: const Text('Mark Delivered'),
                                ),
                              const SizedBox(width: 8),
                              DropdownButton<String>(
                                value: del.status,
                                items: ['Pending', 'Scheduled', 'Out for Delivery', 'Delivered', 'Cancelled', 'Failed']
                                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (newStatus) {
                                  if (newStatus != null) {
                                    provider.updateDeliveryStatus(del.id, newStatus);
                                  }
                                },
                              ),
                            ],
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

  void _showNewDeliveryModal(BuildContext context, AppProvider provider) {
    Customer? selectedCust;
    final invCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final driverCtrl = TextEditingController();
    final vehicleCtrl = TextEditingController();
    final chargeCtrl = TextEditingController(text: '0');

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: const Text('Create New Delivery Dispatch Note'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<Customer>(
                    initialValue: selectedCust,
                    decoration: const InputDecoration(labelText: 'Customer', border: OutlineInputBorder()),
                    items: provider.customers.map((c) => DropdownMenuItem(value: c, child: Text('${c.name} (${c.phone})'))).toList(),
                    onChanged: (c) {
                      setModalState(() {
                        selectedCust = c;
                        if (c != null) {
                          addrCtrl.text = c.address;
                          phoneCtrl.text = c.phone;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: invCtrl, decoration: const InputDecoration(labelText: 'Invoice Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: 'Delivery Address *', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Contact Phone Number', border: OutlineInputBorder())),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', border: OutlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle Number', border: OutlineInputBorder()))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: chargeCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Delivery Charge (Rs.)', border: OutlineInputBorder())),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                onPressed: selectedCust == null || addrCtrl.text.trim().isEmpty
                    ? null
                    : () {
                        provider.createDelivery(
                          invoiceNo: invCtrl.text.trim(),
                          customer: selectedCust!,
                          address: addrCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          driverName: driverCtrl.text.trim(),
                          vehicleNo: vehicleCtrl.text.trim(),
                          deliveryCharge: double.tryParse(chargeCtrl.text) ?? 0,
                        );
                        Navigator.of(context).pop();
                      },
                child: const Text('Create Delivery'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCompleteDeliveryModal(BuildContext context, AppProvider provider, del) {
    final driverCtrl = TextEditingController(text: del.driverName);
    final vehicleCtrl = TextEditingController(text: del.vehicleNo);
    final receivedByCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Complete Delivery #${del.deliveryNo}'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Delivered By (Driver)', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle #', border: OutlineInputBorder())),
              const SizedBox(height: 12),
              TextField(controller: receivedByCtrl, decoration: const InputDecoration(labelText: 'Received By (Customer Rep)', border: OutlineInputBorder())),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            onPressed: () {
              provider.updateDeliveryStatus(
                del.id,
                'Delivered',
                driverName: driverCtrl.text.trim(),
                vehicleNo: vehicleCtrl.text.trim(),
                receivedBy: receivedByCtrl.text.trim(),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Mark Completed'),
          ),
        ],
      ),
    );
  }
}
