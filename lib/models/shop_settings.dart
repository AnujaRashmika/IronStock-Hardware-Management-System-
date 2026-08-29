class ShopSettings {
  final String shopName;
  final String address;
  final String phone;
  final String email;
  final String logoPath;
  final String currency;
  final String invoicePrefix;
  final String receiptPrefix;
  final double lowStockThreshold;
  final bool autoBackupEnabled;
  final String backupDirectory;

  ShopSettings({
    this.shopName = 'Lanka Hardware & Building Materials',
    this.address = 'No 45, Main Street, Colombo, Sri Lanka',
    this.phone = '+94 11 234 5678 / +94 77 123 4567',
    this.email = 'info@lankahardware.lk',
    this.logoPath = '',
    this.currency = 'Rs.',
    this.invoicePrefix = 'INV-',
    this.receiptPrefix = 'REC-',
    this.lowStockThreshold = 20.0,
    this.autoBackupEnabled = true,
    this.backupDirectory = 'Backups',
  });

  Map<String, dynamic> toMap() {
    return {
      'shopName': shopName,
      'address': address,
      'phone': phone,
      'email': email,
      'logoPath': logoPath,
      'currency': currency,
      'invoicePrefix': invoicePrefix,
      'receiptPrefix': receiptPrefix,
      'lowStockThreshold': lowStockThreshold,
      'autoBackupEnabled': autoBackupEnabled ? 1 : 0,
      'backupDirectory': backupDirectory,
    };
  }

  factory ShopSettings.fromMap(Map<String, dynamic> map) {
    return ShopSettings(
      shopName: map['shopName'] ?? 'Lanka Hardware & Building Materials',
      address: map['address'] ?? 'No 45, Main Street, Colombo, Sri Lanka',
      phone: map['phone'] ?? '+94 11 234 5678 / +94 77 123 4567',
      email: map['email'] ?? 'info@lankahardware.lk',
      logoPath: map['logoPath'] ?? '',
      currency: map['currency'] ?? 'Rs.',
      invoicePrefix: map['invoicePrefix'] ?? 'INV-',
      receiptPrefix: map['receiptPrefix'] ?? 'REC-',
      lowStockThreshold: (map['lowStockThreshold'] as num?)?.toDouble() ?? 20.0,
      autoBackupEnabled: map['autoBackupEnabled'] == 1 || map['autoBackupEnabled'] == true,
      backupDirectory: map['backupDirectory'] ?? 'Backups',
    );
  }
}
