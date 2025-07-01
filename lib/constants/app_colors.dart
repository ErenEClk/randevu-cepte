import 'package:flutter/material.dart';

class AppColors {
  // Ana renkler
  static const Color primary = Color(0xFF2E7D32); // Yeşil - güven ve kalite
  static const Color secondary = Color(0xFF4CAF50); // Açık yeşil
  static const Color accent = Color(0xFFFF9800); // Turuncu - dikkat çekici
  
  // Yardımcı renkler
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);
  static const Color info = Color(0xFF1976D2);
  
  // Metin renkleri
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textLight = Color(0xFF9E9E9E);
  
  // Ek renkler
  static const Color lightGrey = Color(0xFFF5F5F5);
  
  // Gölge ve kenarlık
  static const Color border = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  
  // Gradient renkler
  static const List<Color> primaryGradient = [
    Color(0xFF2E7D32),
    Color(0xFF4CAF50),
  ];
  
  static const List<Color> accentGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];
} 