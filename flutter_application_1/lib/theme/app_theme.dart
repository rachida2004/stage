import 'package:flutter/material.dart';

class AppColors {
  // Primary electric blue
  static const primary = Color(0xFF2563EB);
  static const primaryLight = Color(0xFFE6F1FB);
  static const primaryDark = Color(0xFF1D4ED8);

  // Secondary light blue
  static const secondary = Color(0xFF60A5FA);
  static const secondaryLight = Color(0xFFDBEAFE);

  // Success green
  static const success = Color(0xFF16A34A);
  static const successLight = Color(0xFFDCFCE7);

  // Warning amber
  static const warning = Color(0xFFD97706);
  static const warningLight = Color(0xFFFEF3C7);

  // Danger red
  static const danger = Color(0xFFDC2626);
  static const dangerLight = Color(0xFFFEE2E2);

  // Neutral
  static const muted = Color.fromARGB(255, 12, 12, 12);   // secondary text (keep gray for readability)
  static const border = Color(0xFFCBD5E1);  // border (keep gray for visibility)
  static const surface = Colors.white;      // ✅ now white
  static const cardBg = Colors.white;
  static const pageBg = Colors.white;       // ✅ now white

  // Dark mode
  static const darkBg = Color.fromARGB(255, 2, 63, 154);//modifier
  static const darkSurface = Color(0xFF1E293B);
  static const darkCard = Color(0xFF1E293B);
  static const darkBorder = Color(0xFF334155);
  static const darkText = Color(0xFFF1F5F9);
  static const darkTextSec = Color(0xFF94A3B8);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardBg,
      onSurface: const Color(0xFF1E293B),
    ),
    scaffoldBackgroundColor: AppColors.pageBg, // white background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF1E293B),
      elevation: 0,
      shadowColor: Color.fromARGB(0, 32, 2, 229),
      surfaceTintColor: Color.fromARGB(84, 0, 0, 0),
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color.fromARGB(255, 12, 12, 12),// modifier
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardThemeData(
      // ✅ MODIFIÉ : était Color(24,24,24) → noir qui rendait tous les formulaires/dialogs noirs.
      // Remplacé par Colors.white pour que les Card, AlertDialog et BottomSheet
      // aient un fond blanc propre en mode clair.
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    // ✅ AJOUTÉ : dialogTheme explicite pour que AlertDialog et SimpleDialog
    // aient toujours un fond blanc, indépendamment du cardTheme.
    dialogTheme: const DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border, width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      // ✅ MODIFIÉ : était Color(46,7,205) → bleu trop saturé sur fond blanc.
      // Remplacé par Color(0xFF475569) gris foncé professionnel et lisible.
      labelStyle: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
      // ✅ MODIFIÉ : était Color(31,29,56) → trop sombre pour un hint.
      // Remplacé par Color(0xFF94A3B8) gris clair standard pour les placeholders.
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color.fromARGB(255, 37, 235, 93),// couleur bouton connexion
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color.fromARGB(255, 0, 0, 0),
        side: const BorderSide(color: Color.fromARGB(255, 61, 65, 65), width: 0.5),// BORDURE DEs cards avec info
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.surface, // now white
      selectedColor: AppColors.primary,
      labelStyle: const TextStyle(fontSize: 12, color: Color.fromARGB(255, 219, 219, 230)),//modifier
      secondaryLabelStyle: const TextStyle(fontSize: 12, color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: const BorderSide(color: AppColors.border, width: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    ),
    dividerTheme: const DividerThemeData(
      color: Color.fromARGB(255, 3, 3, 3),//modifier
      thickness: 0.5,
      space: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: Color.fromARGB(255, 9, 9, 9),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
  );

  static ThemeData darkTheme = lightTheme.copyWith(
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 37, 19, 235),
      brightness: Brightness.dark,
      primary: const Color.fromARGB(255, 63, 12, 229),
      secondary: const Color.fromARGB(255, 41, 10, 217),
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkText,
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 236, 239, 246),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(173, 0, 241, 72),//bar en haut
      foregroundColor: AppColors.darkText,
      elevation: 0,
      shadowColor: Color.fromARGB(223, 37, 34, 34),
      surfaceTintColor: Colors.transparent,
      titleTextStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.darkText,
        fontFamily: 'Inter',
      ),
    ),
    cardTheme: CardThemeData(
      color: const Color.fromARGB(255, 241, 242, 247),//fond de card de connexion
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color.fromRGBO(18, 18, 19, 1), width: 0.5),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color.fromARGB(255, 248, 250, 255),
      selectedItemColor: Color.fromARGB(255, 8, 8, 255),
      unselectedItemColor: Color.fromARGB(255, 236, 231, 231),
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
  );
}