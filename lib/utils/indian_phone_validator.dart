class IndianPhoneValidator {
  /// Validates an Indian Mobile Number according to DoT / TRAI standards:
  /// - Exactly 10 digits
  /// - Starts with 6, 7, 8, or 9
  /// - Handles optional +91, 91, or 0 prefixes
  /// - Rejects dummy repeated digits (e.g., 9999999999)
  static String? validate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter 10-digit mobile number';
    }

    String clean = value.trim().replaceAll(RegExp(r'[^\d]'), '');

    // Handle country code prefixes (+91 or 0)
    if (clean.length == 12 && clean.startsWith('91')) {
      clean = clean.substring(2);
    } else if (clean.length == 11 && clean.startsWith('0')) {
      clean = clean.substring(1);
    }

    if (clean.length != 10) {
      return 'Mobile number must be exactly 10 digits';
    }

    final firstChar = clean[0];
    if (!['6', '7', '8', '9'].contains(firstChar)) {
      return 'Indian mobile number must start with 6, 7, 8, or 9';
    }

    // Reject dummy numbers with 10 identical digits (e.g., 9999999999 or 0000000000)
    if (RegExp(r'^(\d)\1{9}$').hasMatch(clean)) {
      return 'Enter a valid Indian mobile number';
    }

    return null; // Valid Indian Mobile Number!
  }

  /// Sanitizes phone input into clean 10-digit format
  static String sanitize(String value) {
    String clean = value.trim().replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length == 12 && clean.startsWith('91')) {
      clean = clean.substring(2);
    } else if (clean.length == 11 && clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    return clean;
  }
}
