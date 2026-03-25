import 'package:flutter/material.dart';

class ACTheme {
  // 1.1 — TOKENS DE COULEUR
  static const Color colorBackground = Color(0xFFFFFDD0);
  static const Color colorSurface = Color(0xFFFFF8E7);
  static const Color colorPrimary = Color(0xFFA8D8A8);
  static const Color colorSecondary = Color(0xFFB8E0FF);
  static const Color colorAccentWarm = Color(0xFFFFD4B8);
  static const Color colorAccentGold = Color(0xFFFFD700);
  static const Color colorBorder = Color(0xFFC4956A);
  static const Color colorTextPrimary = Color(0xFF5C4033);
  static const Color colorTextSecondary = Color(0xFF8B6F5E);
  static const Color colorWater = Color(0xFFB8E0FF);
  static const Color colorGrass = Color(0xFF90EE90);
  static const Color colorSkyHigh = Color(0xFFE8F4FD);
  static const Color colorCardOverlay = Color(0x1A000000); // Colors.black.withOpacity(0.1)
  static const Color colorFlash = Color(0x4DFFD4B8); // colorAccentWarm.withOpacity(0.3)

  // 1.2 — SIGNATURE VISUELLE AC : L'OMBRE PLATE 2.5D
  static const BoxShadow shadow25D = BoxShadow(
    color: Color(0x265A3C1E), // rgba(90,60,30,0.15)
    offset: Offset(0, 4), // décalage BAS uniquement
    blurRadius: 0, // ZÉRO blur — ombre nette
    spreadRadius: 0,
  );

  static const double borderSize = 2.5;

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: colorBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colorPrimary,
        primary: colorPrimary,
        secondary: colorSecondary,
        surface: colorSurface,
        onSurface: colorTextPrimary,
      ),
      // 1.4 — TYPOGRAPHIE (OpenDyslexic)
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'OpenDyslexic',
          fontWeight: FontWeight.bold,
          fontSize: 32,
          color: colorTextPrimary,
          height: 1.6,
          letterSpacing: 0.5,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'OpenDyslexic',
          fontWeight: FontWeight.bold,
          fontSize: 24,
          color: colorTextPrimary,
          height: 1.6,
          letterSpacing: 0.5,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'OpenDyslexic',
          fontSize: 18,
          color: colorTextPrimary,
          height: 1.6,
          letterSpacing: 0.5,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'OpenDyslexic',
          fontSize: 18,
          color: colorTextPrimary,
          height: 1.6,
          letterSpacing: 0.5,
        ),
      ),
      // 1.3 — GÉOMÉTRIE & ESPACEMENTS
      cardTheme: CardThemeData(
        color: colorSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: colorBorder, width: borderSize),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colorPrimary,
          foregroundColor: colorTextPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          minimumSize: const Size(56, 56), // Touch target
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: colorBorder, width: borderSize),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontFamily: 'OpenDyslexic',
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// Widget utilitaire pour l'ombre plate 2.5D
class ACFlatShadowDecorator extends StatelessWidget {
  final Widget child;
  final BorderRadius? borderRadius;

  const ACFlatShadowDecorator({
    super.key,
    required this.child,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        boxShadow: const [ACTheme.shadow25D],
      ),
      child: child,
    );
  }
}
