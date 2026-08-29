import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sale.dart';
import '../models/shop_settings.dart';

class InvoiceDialog extends StatefulWidget {
  final Sale sale;
  final ShopSettings shopSettings;

  const InvoiceDialog({
    super.key,
    required this.sale,
    required this.shopSettings,
  });

  @override
  State<InvoiceDialog> createState() => _InvoiceDialogState();
}

class _InvoiceDialogState extends State<InvoiceDialog> {
  bool _isThermalView = true;

  String _formatCurrency(double amount) {
    return '${widget.shopSettings.currency} ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: _isThermalView ? 420 : 700,
        constraints: const BoxConstraints(maxHeight: 800),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Top Action Bar
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  _isThermalView ? 'Thermal Receipt (80mm)' : 'Standard A4 Invoice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('80mm Thermal')),
                    ButtonSegment(value: false, label: Text('A4 Standard')),
                  ],
                  selected: {_isThermalView},
                  onSelectionChanged: (set) {
                    setState(() {
                      _isThermalView = set.first;
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const Divider(height: 24),

            // Printable Invoice Paper Container
            Expanded(
              child: SingleChildScrollView(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _isThermalView ? _buildThermalReceipt() : _buildA4Invoice(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Bottom Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Close'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invoice sent to local printer...')),
                    );
                  },
                  icon: const Icon(Icons.print_rounded),
                  label: const Text('Print Receipt / Invoice'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThermalReceipt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.shopSettings.shopName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          textAlign: TextAlign.center,
        ),
        Text(widget.shopSettings.address, style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        Text('Tel: ${widget.shopSettings.phone}', style: const TextStyle(fontSize: 11), textAlign: TextAlign.center),
        const SizedBox(height: 8),
        const Text('------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Inv #: ${widget.sale.invoiceNo}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            Text(DateFormat('dd/MM/yy HH:mm').format(widget.sale.date), style: const TextStyle(fontSize: 11)),
          ],
        ),
        Row(
          children: [
            Text('Customer: ${widget.sale.customerName}', style: const TextStyle(fontSize: 11)),
          ],
        ),
        const Text('------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),

        // Items Table
        ...widget.sale.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.productName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('  ${item.quantity.toStringAsFixed(1)} ${item.unit} x ${_formatCurrency(item.unitPrice)}', style: const TextStyle(fontSize: 11)),
                      Text(_formatCurrency(item.total), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            )),

        const Text('------------------------------------------', style: TextStyle(fontSize: 10, color: Colors.grey)),

        // Summary
        _buildThermalLine('Subtotal:', widget.sale.subtotal),
        if (widget.sale.discount > 0) _buildThermalLine('Discount:', -widget.sale.discount),
        if (widget.sale.deliveryCharge > 0) _buildThermalLine('Delivery Charge:', widget.sale.deliveryCharge),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('GRAND TOTAL:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(_formatCurrency(widget.sale.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        _buildThermalLine('Paid Amount:', widget.sale.paidAmount),
        if (widget.sale.creditAmount > 0)
          _buildThermalLine('Credit Balance:', widget.sale.creditAmount, isBold: true),

        const SizedBox(height: 8),
        Text('Payment: ${widget.sale.primaryPaymentMethod}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
        const SizedBox(height: 12),
        const Text('Thank You! Come Again.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Container(
          height: 35,
          color: Colors.grey.shade200,
          child: Center(
            child: Text('||||||| | ||||| | ||| ${widget.sale.invoiceNo}', style: const TextStyle(fontSize: 11, letterSpacing: 2)),
          ),
        ),
      ],
    );
  }

  Widget _buildThermalLine(String label, double amount, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(_formatCurrency(amount), style: TextStyle(fontSize: 11, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  Widget _buildA4Invoice() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.shopSettings.shopName,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                Text(widget.shopSettings.address),
                Text('Phone: ${widget.shopSettings.phone} | Email: ${widget.shopSettings.email}'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'SALES INVOICE',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange),
                ),
                Text('Invoice #: ${widget.sale.invoiceNo}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Date: ${DateFormat('dd MMM yyyy HH:mm').format(widget.sale.date)}'),
              ],
            ),
          ],
        ),

        const Divider(height: 32),

        // Bill To & Payment Info
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('BILL TO:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),
                Text(widget.sale.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (widget.sale.customerPhone.isNotEmpty) Text('Phone: ${widget.sale.customerPhone}'),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Payment Method: ${widget.sale.primaryPaymentMethod}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Status: ${widget.sale.paymentStatus}', style: TextStyle(fontWeight: FontWeight.bold, color: widget.sale.paymentStatus == 'Paid' ? Colors.green : Colors.red)),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Item Table
        Table(
          columnWidths: const {
            0: FlexColumnWidth(1),
            1: FlexColumnWidth(3),
            2: FlexColumnWidth(1),
            3: FlexColumnWidth(1.2),
            4: FlexColumnWidth(1.2),
            5: FlexColumnWidth(1.5),
          },
          border: TableBorder.all(color: Colors.grey.shade300),
          children: [
            TableRow(
              decoration: BoxDecoration(color: Colors.grey.shade100),
              children: [
                const Padding(padding: EdgeInsets.all(8), child: Text('#', style: TextStyle(fontWeight: FontWeight.bold))),
                const Padding(padding: EdgeInsets.all(8), child: Text('Item Description', style: TextStyle(fontWeight: FontWeight.bold))),
                const Padding(padding: EdgeInsets.all(8), child: Text('Unit', style: TextStyle(fontWeight: FontWeight.bold))),
                const Padding(padding: EdgeInsets.all(8), child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold))),
                const Padding(padding: EdgeInsets.all(8), child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                Padding(padding: const EdgeInsets.all(8), child: Text('Total (${widget.shopSettings.currency})', style: const TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
            ...widget.sale.items.asMap().entries.map((entry) {
              final idx = entry.key + 1;
              final item = entry.value;
              return TableRow(
                children: [
                  Padding(padding: const EdgeInsets.all(8), child: Text('$idx')),
                  Padding(padding: const EdgeInsets.all(8), child: Text(item.productName)),
                  Padding(padding: const EdgeInsets.all(8), child: Text(item.unit)),
                  Padding(padding: const EdgeInsets.all(8), child: Text(item.quantity.toStringAsFixed(1))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(_formatCurrency(item.unitPrice))),
                  Padding(padding: const EdgeInsets.all(8), child: Text(_formatCurrency(item.total), style: const TextStyle(fontWeight: FontWeight.bold))),
                ],
              );
            }),
          ],
        ),

        const SizedBox(height: 20),

        // Total Summary
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 300,
              child: Column(
                children: [
                  _buildSummaryRow('Subtotal', _formatCurrency(widget.sale.subtotal)),
                  if (widget.sale.discount > 0) _buildSummaryRow('Discount', '- ${_formatCurrency(widget.sale.discount)}'),
                  if (widget.sale.deliveryCharge > 0) _buildSummaryRow('Delivery Charge', _formatCurrency(widget.sale.deliveryCharge)),
                  const Divider(),
                  _buildSummaryRow('Grand Total', _formatCurrency(widget.sale.totalAmount), isBold: true),
                  _buildSummaryRow('Paid Amount', _formatCurrency(widget.sale.paidAmount)),
                  if (widget.sale.creditAmount > 0)
                    _buildSummaryRow('Outstanding Balance', _formatCurrency(widget.sale.creditAmount), isBold: true, color: Colors.red),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 40),

        // Signatures
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Container(width: 150, height: 1, color: Colors.black),
                const SizedBox(height: 4),
                const Text('Customer Signature', style: TextStyle(fontSize: 12)),
              ],
            ),
            Column(
              children: [
                Container(width: 150, height: 1, color: Colors.black),
                const SizedBox(height: 4),
                const Text('Authorized Stamp / Signature', style: TextStyle(fontSize: 12)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }
}
