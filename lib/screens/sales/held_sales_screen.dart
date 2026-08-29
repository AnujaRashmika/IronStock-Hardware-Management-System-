import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../providers/app_provider.dart';

class HeldSalesScreen extends StatelessWidget {
  const HeldSalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Held POS Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: provider.heldSales.isEmpty
                  ? const Center(child: Text('No held sales carts.'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: provider.heldSales.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final held = provider.heldSales[index];
                        final subtotal = held.cartItems.fold(0.0, (sum, item) => sum + item.total);

                        return ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.amber,
                            child: Icon(Icons.pause_circle_filled_rounded, color: Colors.white),
                          ),
                          title: Text('${held.label} (${held.customer.name})', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Held Date: ${DateFormat('dd MMM yyyy HH:mm').format(held.date)} | ${held.cartItems.length} items in cart'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Rs. ${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                onPressed: () {
                                  provider.resumeHeldSale(held);
                                  provider.setScreen('pos');
                                },
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: const Text('Resume Session'),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => provider.deleteHeldSale(held.id),
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
}
