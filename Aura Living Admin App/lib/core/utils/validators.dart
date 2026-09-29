/// Form validation rules per Aura Living PRD specification
class AppValidators {
  AppValidators._();

  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$',
  );

  static final RegExp _alphanumericRegExp = RegExp(r'^[A-Z0-9_-]+$');

  /// Validates work email address
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates admin password (minimum 8 characters)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    return null;
  }

  /// Validates generic required field
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates positive base price (> 0) in BDT (৳)
  static String? validateBasePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Base price is required';
    }
    final clean = value.replaceAll('\$', '').replaceAll('৳', '').replaceAll(',', '').trim();
    final parsed = double.tryParse(clean);
    if (parsed == null) {
      return 'Enter a valid numeric price';
    }
    if (parsed <= 0) {
      return 'Base price must be greater than ৳0.00';
    }
    return null;
  }

  /// Validates Bangladeshi phone numbers (+8801XXXXXXXXX or 01XXXXXXXXX)
  static String? validateBangladeshPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final clean = value.replaceAll(RegExp(r'[\s\-]'), '');
    final bdPhoneRegex = RegExp(r'^(?:\+?880|0)1[3-9]\d{8}$');
    if (!bdPhoneRegex.hasMatch(clean)) {
      return 'Enter a valid Bangladesh mobile (+8801XXXXXXXXX or 01XXXXXXXXX)';
    }
    return null;
  }

  /// Validates discount percentage (0 to 90%)
  static String? validateDiscount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Defaults to 0
    }
    final parsed = double.tryParse(value.replaceAll('%', '').trim());
    if (parsed == null) {
      return 'Enter a valid discount number';
    }
    if (parsed < 0) {
      return 'Discount cannot be negative';
    }
    if (parsed > 90) {
      return 'Discount cannot exceed 90%';
    }
    return null;
  }

  /// Validates stock quantity (integer >= 0)
  static String? validateStock(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Stock quantity is required';
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) {
      return 'Enter a valid integer quantity';
    }
    if (parsed < 0) {
      return 'Stock count cannot be negative';
    }
    return null;
  }

  /// Validates uppercase alphanumeric coupon code
  static String? validateCouponCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Coupon code is required';
    }
    final clean = value.trim().toUpperCase();
    if (clean.length < 3) {
      return 'Code must be at least 3 characters';
    }
    if (!_alphanumericRegExp.hasMatch(clean)) {
      return 'Code must only contain letters, numbers, or dashes';
    }
    return null;
  }
}
