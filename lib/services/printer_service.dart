import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PrinterService {
  PrinterService._();
  static final PrinterService instance = PrinterService._();

  Future<void> printSaleBill({
    required String shopName,
    required String shopAddress,
    required String shopPhone,
    required String invoiceNo,
    required String customerName,
    required String date,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double discount,
    required double tax,
    required double deliveryCharge,
    required double total,
    required double paid,
    required double balance,
    String footer = 'Thank you!',
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Center(
                child: pw.Text(shopName.toUpperCase(),
                    style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                    textAlign: pw.TextAlign.center),
              ),
              if (shopAddress.isNotEmpty)
                pw.Center(child: pw.Text(shopAddress, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
              if (shopPhone.isNotEmpty)
                pw.Center(child: pw.Text('Tel: $shopPhone', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
              pw.SizedBox(height: 6),
              pw.Divider(),
              pw.Text('Invoice: $invoiceNo', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('Customer: $customerName', style: const pw.TextStyle(fontSize: 10)),
              pw.Divider(),
              ...items.map((item) {
                final name = item['product_name']?.toString() ?? '';
                final qty = item['quantity'];
                final lineTotal = item['total'];
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 3),
                  child: pw.Row(children: [
                    pw.Expanded(flex: 4, child: pw.Text(name, style: const pw.TextStyle(fontSize: 9))),
                    pw.Expanded(flex: 1, child: pw.Text('$qty', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                    pw.Expanded(flex: 2, child: pw.Text('${(lineTotal as num).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.right)),
                  ]),
                );
              }),
              pw.Divider(),
              _row('Subtotal', subtotal),
              if (discount > 0) _row('Discount', -discount),
              if (tax > 0) _row('Tax', tax),
              if (deliveryCharge > 0) _row('Delivery', deliveryCharge),
              _row('Total', total, bold: true),
              _row('Paid', paid),
              if (balance > 0) _row('Balance', balance),
              pw.SizedBox(height: 8),
              pw.Center(child: pw.Text(footer, style: const pw.TextStyle(fontSize: 9), textAlign: pw.TextAlign.center)),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Bill_$invoiceNo',
      format: PdfPageFormat.roll80,
    );
  }

  Future<void> printReport({
    required String shopName,
    required String title,
    required String period,
    required Map<String, double> totals,
  }) async {
    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(shopName, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(title, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.Text('Period: $period', style: const pw.TextStyle(fontSize: 11)),
              pw.SizedBox(height: 16),
              ...totals.entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(e.key, style: const pw.TextStyle(fontSize: 12)),
                        pw.Text(e.value.toStringAsFixed(2), style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (format) async => doc.save(),
      name: 'Report_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  pw.Widget _row(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: bold ? 11 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value.toStringAsFixed(2), style: pw.TextStyle(fontSize: bold ? 11 : 10, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}
