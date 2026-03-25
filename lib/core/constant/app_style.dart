import 'package:flutter/material.dart';
import 'package:pulse_chat/core/constant/app_color.dart';

class AppStyles {
  AppStyles._();

  // Headings
  static const TextStyle heading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle splashTitle = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: AppColors.white,
    letterSpacing: 1.5,
  );

  static const TextStyle splashSubtitle = TextStyle(
    fontSize: 14,
    color: AppColors.white70,
  );

  // Body
  static const TextStyle subtitle = TextStyle(
    fontSize: 16,
    color: AppColors.grey,
  );

  static const TextStyle buttonText = TextStyle(fontSize: 16);

  static const TextStyle labelMedium = TextStyle(fontWeight: FontWeight.w500);

  // Message
  static const TextStyle messageTextMe = TextStyle(
    color: AppColors.white,
    fontSize: 15,
  );

  static const TextStyle messageTextOther = TextStyle(
    color: AppColors.black87,
    fontSize: 15,
  );

  // Button style
  static ButtonStyle primaryButton = ElevatedButton.styleFrom(
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
  );
}
