import 'package:intl/intl.dart';

class CurrencyUtils {
  static final _fmt = NumberFormat('#,##0.00', 'en_US');
  static String format(num value, [String symbol = 'Rs.']) =>
      '$symbol ${_fmt.format(value)}';
  static String formatPlain(num value) => _fmt.format(value);
}
