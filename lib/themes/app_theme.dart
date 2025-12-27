import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The main theme configuration for the FinanceFlow app
class AppTheme {
  // Brand Colors
  static const Color primaryColor = Color(0xFF3F51B5); // Indigo
  static const Color secondaryColor = Color(0xFF303F9F); // Darker Indigo
  static const Color accentColor = Color(0xFF4CAF50); // Green
  static const Color backgroundColor = Color(0xFFFAFAFA); // Slightly lighter than before
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF212121); // Almost black
  static const Color secondaryTextColor = Color(0xFF757575); // Medium gray
  static const Color dividerColor = Color(0xFFEEEEEE); // Lighter gray for dividers
  
  // Additional colors for UI elements
  static const Color surfaceColor = Colors.white;
  static const Color onSurfaceColor = Color(0xFF212121);
  static const Color shadowColor = Color(0x1A000000); // 10% black shadow
  
  // Income and expense colors
  static const Color incomeColor = Color(0xFF4CAF50); // Green
  static const Color expenseColor = Color(0xFFE91E63); // Pink
  static const Color transferColor = Color(0xFF2196F3); // Blue
  
  // Status colors
  static const Color warningColor = Color(0xFFFFC107); // Amber
  static const Color successColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color infoColor = Color(0xFF2196F3); // Blue
  static const Color neutralColor = Color(0xFF9E9E9E); // Gray
  
  // Category colors
  static const Map<String, Color> categoryColors = {
    'Food': Color(0xFFF44336),
    'Transport': Color(0xFF2196F3),
    'Shopping': Color(0xFF9C27B0),
    'Bills': Color(0xFFFF9800),
    'Entertainment': Color(0xFF795548),
    'Health': Color(0xFF4CAF50),
    'Housing': Color(0xFF607D8B),
    'Other': Color(0xFF9E9E9E),
  };
  
  /// Get system overlay style for status bar
  static SystemUiOverlayStyle get systemOverlayStyle => SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: backgroundColor,
    systemNavigationBarIconBrightness: Brightness.dark,
  );
  
  /// Rounded corner radius used throughout the app
  static const double borderRadius = 16.0;
  
  /// Default elevation for cards and surfaces
  static const double defaultElevation = 2.0;

  /// Default box shadow for cards
  static final List<BoxShadow> boxShadow = [
    BoxShadow(
      color: shadowColor,
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];
  
  /// Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  /// The light theme for the app
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      secondary: accentColor,
      surface: backgroundColor,
      error: errorColor,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: textColor,
      onError: Colors.white,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: backgroundColor,
    cardTheme: CardTheme(
      color: cardColor,
      elevation: defaultElevation,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      shadowColor: shadowColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(borderRadius)),
      ),
      systemOverlayStyle: systemOverlayStyle,
      titleTextStyle: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      headlineSmall: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textColor,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textColor,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: secondaryTextColor,
      ),
    ),
    buttonTheme: ButtonThemeData(
      buttonColor: primaryColor,
      textTheme: ButtonTextTheme.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        elevation: defaultElevation,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      elevation: 4,
      shape: CircleBorder(),
      extendedPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: dividerColor,
      thickness: 1,
      space: 16,
      indent: 8,
      endIndent: 8,
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: BorderSide.none,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      filled: true,
      fillColor: surfaceColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      labelStyle: const TextStyle(color: secondaryTextColor),
      hintStyle: TextStyle(color: secondaryTextColor.withAlpha(179)),
      prefixIconColor: primaryColor,
      suffixIconColor: secondaryTextColor,
      // Add subtle shadow to input fields
      isDense: true,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
    ),
    
    // Tab bar theme
    tabBarTheme: TabBarTheme(
      labelColor: Colors.white,
      unselectedLabelColor: Colors.white.withAlpha(179),
      indicatorSize: TabBarIndicatorSize.tab,
      labelStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      unselectedLabelStyle: const TextStyle(fontSize: 16),
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: Colors.white.withAlpha(51),
      ),
    ),
    
    // Chip theme
    chipTheme: ChipThemeData(
      backgroundColor: surfaceColor,
      disabledColor: dividerColor,
      selectedColor: primaryColor.withAlpha(51),
      secondarySelectedColor: primaryColor,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(fontSize: 14),
      secondaryLabelStyle: const TextStyle(fontSize: 14, color: Colors.white),
      brightness: Brightness.light,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      elevation: 0,
    ),
    
    // Bottom navigation bar theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: surfaceColor,
      selectedItemColor: primaryColor,
      unselectedItemColor: secondaryTextColor,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 12),
    ),
    
    // Bottom sheet theme
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surfaceColor,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(borderRadius * 1.5)),
      ),
      modalElevation: 10,
      clipBehavior: Clip.antiAlias,
    ),
  );
}
