import 'package:intl/intl.dart';

/// Bangladeshi Taka (BDT ৳) and International Currency Formatter
class CurrencyFormatter {
  // BDT standard symbol
  static const String defaultSymbol = '৳';

  /// Format an amount into Bangladeshi Taka (e.g., ৳34,900 or ৳1,250.50)
  static String format(double amount, {String symbol = defaultSymbol}) {
    if (symbol == defaultSymbol) {
      if (amount % 1 == 0) {
        final formatter = NumberFormat('#,##,###', 'en_IN');
        return '$defaultSymbol${formatter.format(amount.toInt())}';
      } else {
        final formatter = NumberFormat('#,##,###.00', 'en_IN');
        return '$defaultSymbol${formatter.format(amount)}';
      }
    }
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: (amount % 1 == 0) ? 0 : 2,
    );
    return formatter.format(amount);
  }

  /// Format standard with 2 decimal places or full precision
  static String formatStandard(double amount, {String symbol = defaultSymbol}) {
    if (symbol == defaultSymbol) {
      final formatter = NumberFormat('#,##,###.00', 'en_IN');
      return '$defaultSymbol${formatter.format(amount)}';
    }
    final formatter = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  /// Format compact without decimals (e.g. ৳34,900)
  static String formatCompact(double amount, {String symbol = defaultSymbol}) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '$symbol${formatter.format(amount.round())}';
  }
}

