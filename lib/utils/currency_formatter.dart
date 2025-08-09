import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _polishFormatter = NumberFormat.currency(
    locale: 'pl_PL',
    symbol: 'zł',
    decimalDigits: 2,
  );

  /// Format a number as Polish currency (PLN)
  static String formatPLN(double amount) {
    return _polishFormatter.format(amount);
  }

  /// Format a number as Polish currency from string
  static String formatPLNFromString(String amount) {
    final double value = double.tryParse(amount) ?? 0.0;
    return formatPLN(value);
  }

  /// Format with custom currency symbol (for backward compatibility)
  static String formatWithSymbol(double amount, String symbol) {
    // For non-PLN currencies, use simple formatting
    return '${amount.toStringAsFixed(2)} $symbol';
  }
}
