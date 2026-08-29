import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:iron_stock/models/purchase.dart';
import 'package:iron_stock/providers/app_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('AppProvider Unit Tests', () {
    late AppProvider provider;

    setUp(() async {
      provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 500));
    });

    test('Initial database seed loads products, categories, customers, and suppliers', () {
      expect(provider.products.isNotEmpty, isTrue);
      expect(provider.categories.isNotEmpty, isTrue);
      expect(provider.customers.isNotEmpty, isTrue);
      expect(provider.suppliers.isNotEmpty, isTrue);
    });

    test('Cart calculations and Checkout reduces stock and creates sale', () async {
      final product = provider.products.first;
      final initialStock = product.currentStock;

      provider.clearCart();
      provider.addToCart(product, quantity: 2.0);

      expect(provider.cart.length, equals(1));
      expect(provider.cartSubtotal, equals(product.sellingPrice * 2.0));

      final customer = provider.customers.firstWhere((c) => c.customerType == 'Walk-in');
      final sale = await provider.checkoutSale(
        customer: customer,
        paidAmount: provider.cartTotal,
        primaryPaymentMethod: 'Cash',
      );

      expect(sale, isNotNull);
      expect(sale!.totalAmount, equals(product.sellingPrice * 2.0));
      expect(sale.paidAmount, equals(product.sellingPrice * 2.0));

      final updatedProduct = provider.products.firstWhere((p) => p.id == product.id);
      expect(updatedProduct.currentStock, equals(initialStock - 2.0));
    });

    test('Purchase increases stock and tracks supplier balance if credit', () async {
      final supplier = provider.suppliers.first;
      final product = provider.products.first;
      final initialStock = product.currentStock;
      final initialSupplierBalance = supplier.balance;

      await provider.addPurchase(
        supplier: supplier,
        supplierInvoiceNo: 'SUP-INV-100',
        date: DateTime.now(),
        items: [
          PurchaseItem(
            productId: product.id,
            productCode: product.code,
            productName: product.name,
            unit: product.unit,
            quantity: 10.0,
            purchasePrice: product.purchasePrice,
            total: 10.0 * product.purchasePrice,
          ),
        ],
        discount: 0.0,
        paidAmount: 0.0,
        paymentMethod: 'Credit',
      );

      final updatedProduct = provider.products.firstWhere((p) => p.id == product.id);
      expect(updatedProduct.currentStock, equals(initialStock + 10.0));

      final updatedSupplier = provider.suppliers.firstWhere((s) => s.id == supplier.id);
      expect(updatedSupplier.balance, equals(initialSupplierBalance + (10.0 * product.purchasePrice)));
    });

    test('Customer credit payment reduces customer balance', () async {
      final customer = provider.customers.firstWhere((c) => c.balance > 0, orElse: () => provider.customers.first);
      final initialBalance = customer.balance;

      if (initialBalance > 0) {
        await provider.recordCustomerPayment(
          customer: customer,
          amount: 1000.0,
          paymentMethod: 'Cash',
        );

        final updatedCust = provider.customers.firstWhere((c) => c.id == customer.id);
        expect(updatedCust.balance, equals(initialBalance - 1000.0));
      }
    });

    test('Day closing expected cash reconciliation', () async {
      final dayClosing = await provider.performDayClosing(
        cashierName: 'Test Cashier',
        openingCash: 5000.0,
        actualCash: 5000.0,
      );

      expect(dayClosing.openingCash, equals(5000.0));
      expect(dayClosing.actualCash, equals(5000.0));
      expect(provider.dayClosings.isNotEmpty, isTrue);
    });
  });
}
