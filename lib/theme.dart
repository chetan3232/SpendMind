import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Theme Colors
  static const Color obsidianBg = Color(0xFF0B0F19); // Fallback color format
  static const Color background = Color(0xFF0B0F19);
  static const Color cardColor = Color(0xFF1F2937);
  static const Color borderColor = Color(0x1AFFFFFF); // 10% white
  static const Color textPrimary = Color(0xFFF3F4F6);
  static const Color textSecondary = Color(0xFF9CA3AF);

  // Accent Colors
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color coralRed = Color(0xFFEF4444);
  static const Color vibrantPurple = Color(0xFF8B5CF6);
  static const Color mutedBlue = Color(0xFF3B82F6);

  // Gradient definitions
  static const LinearGradient bgGradient = LinearGradient(
    colors: [Color(0xFF0B0F19), Color(0xFF111827), Color(0xFF05050A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient savingsGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: vibrantPurple,
      colorScheme: const ColorScheme.dark(
        primary: vibrantPurple,
        secondary: emeraldGreen,
        error: coralRed,
        surface: cardColor,
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          titleLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.normal),
          bodyMedium: TextStyle(color: textSecondary, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }

  // Reuseable Glassmorphic Box Decoration
  static BoxDecoration glassDecoration({
    dynamic borderRadius = 16.0,
    Color color = const Color(0xFF1F2937),
    double opacity = 0.4,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: opacity),
      borderRadius: borderRadius is double ? BorderRadius.circular(borderRadius) : borderRadius as BorderRadiusGeometry?,
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.08),
        width: 1.0,
      ),
    );
  }

  // Glassmorphic Card Wrapper Component
  static Widget glassCard({
    required Widget child,
    dynamic borderRadius = 16.0,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(16.0),
    Color color = const Color(0xFF1F2937),
    double opacity = 0.4,
    double blur = 12.0,
  }) {
    return ClipRRect(
      borderRadius: borderRadius is double ? BorderRadius.circular(borderRadius) : (borderRadius as BorderRadiusGeometry? ?? BorderRadius.zero),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: glassDecoration(
            borderRadius: borderRadius,
            color: color,
            opacity: opacity,
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
