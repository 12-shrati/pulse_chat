import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF4A00E0);
  static const Color primaryLight = Color(0xFF8E2DE2);

  // Neutrals
  static const Color white = Colors.white;
  static const Color black87 = Colors.black87;
  static const Color grey = Colors.grey;
  static Color grey100 = Colors.grey.shade100;
  static Color grey200 = Colors.grey.shade200;
  static Color grey300 = Colors.grey.shade300;
  static Color grey500 = Colors.grey.shade500;
  static Color grey600 = Colors.grey.shade600;

  // Status
  static const Color online = Colors.greenAccent;
  static const Color offline = Colors.redAccent;
  static const Color error = Colors.red;
  static const Color white70 = Colors.white70;

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
