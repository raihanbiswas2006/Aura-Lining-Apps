import 'package:intl/intl.dart';

/// Formatting utilities for currency, dates, quantities, and IDs
class AppFormatters {
  AppFormatters._();

  static const String currencySymbol = '৳';

  static final DateFormat _dateTimeFormat = DateFormat('MMM dd, yyyy • HH:mm');
  static final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// Formats monetary amount in BDT, e.g. ৳34,900 or ৳1,250.50
  static String currency(num amount) {
    if (amount % 1 == 0) {
      final formatter = NumberFormat('#,##,###', 'en_IN');
      return '$currencySymbol${formatter.format(amount.toInt())}';
    }
    final formatter = NumberFormat('#,##,###.00', 'en_IN');
    return '$currencySymbol${formatter.format(amount)}';
  }

  static String formatCurrency(num amount) => currency(amount);

  /// Formats monetary amount without decimal cents, e.g. ৳34,900
  static String compactCurrency(num amount) {
    final formatter = NumberFormat('#,##,###', 'en_IN');
    return '$currencySymbol${formatter.format(amount.round())}';
  }


  /// Formats timestamp as: Oct 24, 2026 • 14:32
  static String dateTime(DateTime dt) {
    return _dateTimeFormat.format(dt);
  }

  static String formatDateTime(DateTime dt) => dateTime(dt);

  /// Formats timestamp as: Oct 24, 2026
  static String dateOnly(DateTime dt) {
    return _dateFormat.format(dt);
  }

  static String formatDate(DateTime dt) => dateOnly(dt);

  /// Formats timestamp as: 14:32
  static String timeOnly(DateTime dt) {
    return _timeFormat.format(dt);
  }

  /// Formats relative time (e.g. 5m ago, 2h ago, Yesterday)
  static String relativeTime(DateTime dt) {
    final now = DateTime.now();
    final difference = now.difference(dt);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _dateFormat.format(dt);
    }
  }

  static String formatRelativeTime(DateTime dt) => relativeTime(dt);

  /// Formats order ID display
  static String orderId(String id) {
    if (id.startsWith('#')) return id;
    return '#$id';
  }

  static String formatOrderId(String id) => orderId(id);
}
