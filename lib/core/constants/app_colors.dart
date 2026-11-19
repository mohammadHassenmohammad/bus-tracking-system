import 'package:flutter/material.dart';

/// Design System Color Palette: Premium Navy, White, Royal Blue, with accessible semantic states
class AppColors {
  // Brand Primary & Navy Accents
  static const Color primaryNavy = Color(0xFF0A192F);
  static const Color secondaryNavy = Color(0xFF172A45);
  static const Color lightNavy = Color(0xFF233554);
  static const Color primaryBlue = Color(0xFF1E88E5);
  static const Color accentCyan = Color(0xFF64FFDA);
  static const Color skyBlue = Color(0xFF00B4D8);

  // Backgrounds & Surfaces
  static const Color backgroundLight = Color(0xFFF4F7FB);
  static const Color cardSurfaceLight = Color(0xFFFFFFFF);
  static const Color darkBackground = Color(0xFF070D18);
  static const Color darkCardSurface = Color(0xFF0F172A);

  // Text Colors
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textWhite = Color(0xFFFFFFFF);

  // Semantic & Vehicle Status Colors
  static const Color statusMoving = Color(0xFF10B981);       // Emerald Green
  static const Color statusStationary = Color(0xFF3B82F6);   // Blue
  static const Color statusDelayed = Color(0xFFF59E0B);      // Amber
  static const Color statusOffline = Color(0xFF6B7280);      // Gray
  static const Color statusBreakdown = Color(0xFFEF4444);    // Red
  static const Color statusEmergency = Color(0xFFDC2626);    // Deep Red Alert

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF1E293B);

  // Card Shadows
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

