class DateFormatter {
  static String formatDDMMYYYY(String? rawDate) {
    if (rawDate == null || rawDate.trim().isEmpty) return '-';
    try {
      final dt = DateTime.parse(rawDate.trim());
      final day = dt.day.toString().padLeft(2, '0');
      final month = dt.month.toString().padLeft(2, '0');
      final year = dt.year;
      return '$day/$month/$year';
    } catch (_) {
      try {
        final dateOnly = rawDate.split('T')[0].trim();
        final parts = dateOnly.split('-');
        if (parts.length == 3) {
          final y = parts[0];
          final m = parts[1].padLeft(2, '0');
          final d = parts[2].padLeft(2, '0');
          return '$d/$m/$y';
        }
      } catch (_) {}
      return rawDate;
    }
  }
}
