import 'package:flutter/material.dart';

class AppColors {
  static const Color tealPrimary = Color(0xFF008080);
  static const Color tealDark = Color(0xFF004D4D);
  static const Color tealDeep = Color(0xFF003333);
  static const Color tealLight = Color(0xFFE6F2F2);
  static const Color emerald = Color(0xFF10B981);

  static const Color goldPrimary = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFFDE047);

  static const Color roseGoldPrimary = Color(0xFFB76E79);
  static const Color roseGoldLight = Color(0xFFE8A598);

  static const Color darkBackground = Color(0xFFF8FAFC);
  static const Color darkCard = Colors.white;

  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightCard = Colors.white;
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: const ColorScheme.light(
        primary: AppColors.tealPrimary,
        secondary: AppColors.goldPrimary,
        tertiary: AppColors.roseGoldPrimary,
        surface: AppColors.lightCard,
        onSurface: Color(0xFF0F172A),
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF0F172A),
        elevation: 1,
        scrolledUnderElevation: 2,
        iconTheme: IconThemeData(color: Color(0xFF0F172A)),
        actionsIconTheme: IconThemeData(color: Color(0xFF0F172A)),
        titleTextStyle: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        modalBackgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 8,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightCard,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: AppColors.tealPrimary.withOpacity(0.25), width: 1.5),
        ),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 18, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(color: Color(0xFF0F172A), fontSize: 14),
        bodyLarge: TextStyle(color: Color(0xFF0F172A), fontSize: 16),
        bodySmall: TextStyle(color: Color(0xFF475569), fontSize: 12),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF334155), fontSize: 14, fontWeight: FontWeight.w500),
        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
        floatingLabelStyle: const TextStyle(color: AppColors.tealPrimary, fontWeight: FontWeight.bold, fontSize: 13),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.tealPrimary, width: 2),
        ),
      ),
    );
  }

  // Dark Theme disabled - redirects to Light Theme exclusively
  static ThemeData get darkTheme => lightTheme;
}
