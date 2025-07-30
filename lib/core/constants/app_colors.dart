import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors (Simple & Elegant)
  static const Color primary = Color(0xFF2B2D42);          // Dark Blue-Gray
  static const Color primaryLight = Color(0xFF8D99AE);     // Light Blue-Gray
  static const Color primaryDark = Color(0xFF1A1B2E);      // Darker variant

  // Background & Surface
  static const Color background = Color(0xFFFAFAFA);       // Off-white
  static const Color surface = Color(0xFFFFFFFF);          // Pure white
  static const Color surfaceVariant = Color(0xFFF5F5F5);   // Light gray

  // Text Colors
  static const Color textPrimary = Color(0xFF2B2D42);      // Dark
  static const Color textSecondary = Color(0xFF8D99AE);    // Medium gray
  static const Color textHint = Color(0xFFBDBDBD);         // Light gray

  // Status Colors (Minimal)
  static const Color success = Color(0xFF27AE60);          // Green
  static const Color warning = Color(0xFFF39C12);          // Orange
  static const Color error = Color(0xFFE74C3C);            // Red
  static const Color info = Color(0xFF3498DB);             // Blue

  // Order Status Colors
  static const Color pending = Color(0xFFF39C12);          // Orange
  static const Color accepted = Color(0xFF3498DB);         // Blue
  static const Color pickedUp = Color(0xFF9B59B6);         // Purple
  static const Color inTransit = Color(0xFFE67E22);        // Dark orange
  static const Color delivered = Color(0xFF27AE60);        // Green
  static const Color cancelled = Color(0xFFE74C3C);        // Red

  // Borders & Dividers
  static const Color border = Color(0xFFE0E0E0);           // Light border
  static const Color divider = Color(0xFFEEEEEE);          // Very light

  // Online/Offline Status
  static const Color online = Color(0xFF27AE60);           // Green
  static const Color offline = Color(0xFF95A5A6);          // Gray

  // Gradients (Optional for buttons)
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}