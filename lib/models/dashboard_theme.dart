
import 'package:flutter/material.dart';

class DashboardTheme {
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color cardColor;
  final Color textColor;

  const DashboardTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.cardColor,
    required this.textColor,
  });

  static DashboardTheme defaultTheme() {
    return DashboardTheme(
      primaryColor: Colors.indigo,
      secondaryColor: Colors.indigoAccent,
      accentColor: Colors.orange,
      backgroundColor: Colors.grey[100]!,
      cardColor: Colors.white,
      textColor: Colors.grey[800]!,
    );
  }
}