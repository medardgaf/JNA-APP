import 'package:flutter/material.dart';

/// Thème de couleurs unifié pour l'application JNA ADMINISTRATION
class AppColors {
  // Couleurs principales
  static const Color primary = Color(0xFF4A90E2); // Bleu principal
  static const Color primaryDark = Color(0xFF357ABD); // Bleu foncé
  static const Color primaryLight = Color(0xFF6BA3E8); // Bleu clair

  // Couleurs d'état
  static const Color success = Color(0xFF5CB85C); // Vert
  static const Color warning = Color(0xFFF0AD4E); // Orange
  static const Color danger = Color(0xFFD9534F); // Rouge
  static const Color info = Color(0xFF5BC0DE); // Bleu clair
  static const Color purple = Color(0xFF9B59B6); // Violet

  // Couleurs de fond
  static const Color background = Color(0xFFF5F7FA); // Gris très clair
  static const Color surface = Colors.white;
  static const Color surfaceLight = Color(0xFFFAFBFC);

  // Couleurs de texte
  static const Color textPrimary = Color(0xFF2C3E50); // Gris foncé
  static const Color textSecondary = Color(0xFF7F8C8D); // Gris moyen
  static const Color textLight = Color(0xFFBDC3C7); // Gris clair
  static const Color textOnPrimary = Colors.white;

  // Couleurs fonctionnelles
  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFECEFF1);
  static const Color shadow = Color(0x1A000000);

  // Couleurs spécifiques métier
  static const Color recette = success; // Vert pour recettes/entrées
  static const Color depense = danger; // Rouge pour dépenses/sorties
  static const Color cotisation = primary; // Bleu pour cotisations
  static const Color don = purple; // Violet pour dons
  static const Color arriere = warning; // Orange pour arriérés

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [success, Color(0xFF4CAF50)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Opacités
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }

  // Couleurs avec opacité prédéfinies
  static Color get primaryLight10 => primary.withOpacity(0.1);
  static Color get primaryLight20 => primary.withOpacity(0.2);
  static Color get successLight10 => success.withOpacity(0.1);
  static Color get successLight20 => success.withOpacity(0.2);
  static Color get dangerLight10 => danger.withOpacity(0.1);
  static Color get dangerLight20 => danger.withOpacity(0.2);
  static Color get warningLight10 => warning.withOpacity(0.1);
  static Color get warningLight20 => warning.withOpacity(0.2);
}

/// Thème complet de l'application
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.purple,
        surface: AppColors.surface,
        error: AppColors.danger,
        onPrimary: AppColors.textOnPrimary,
        onSecondary: AppColors.textOnPrimary,
        onSurface: AppColors.textPrimary,
        onError: AppColors.textOnPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 2,
        shadowColor: AppColors.shadow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnPrimary,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnPrimary,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1,
      ),
    );
  }
}

/// Styles de texte réutilisables
class AppTextStyles {
  static const TextStyle heading1 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle heading3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.textLight,
  );

  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );
}

/// Espacements standardisés
class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Rayons de bordure standardisés
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double round = 999.0;
}
