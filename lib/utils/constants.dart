import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2196F3);
  static const Color primaryLight = Color(0xFF64B5F6);
  static const Color primaryDark = Color(0xFF1976D2);
  
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color info = Color(0xFF2196F3);
  
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color divider = Color(0xFFBDBDBD);
}

class AppStrings {
  static const String appName = 'Gestionnaire de Mots de Passe';
  static const String adminUsername = 'ahmadtidjan';
  static const String adminPassword = 'password123';
  
  static const String loginTitle = 'Connexion';
  static const String registerTitle = 'Inscription';
  static const String welcome = 'Bienvenue';
  
  static const String username = 'Nom d\'utilisateur';
  static const String email = 'Email';
  static const String password = 'Mot de passe';
  static const String confirmPassword = 'Confirmer le mot de passe';
  
  static const String loginButton = 'Se connecter';
  static const String registerButton = 'S\'inscrire';
  static const String logoutButton = 'Déconnexion';
  
  static const String noAccount = 'Pas encore de compte ?';
  static const String haveAccount = 'Déjà un compte ?';
  static const String forgotPassword = 'Mot de passe oublié ?';
}

class AppConstants {
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minUsernameLength = 3;
  static const int maxUsernameLength = 20;
  
  static const int passwordStrengthVeryWeak = 1;
  static const int passwordStrengthWeak = 2;
  static const int passwordStrengthMedium = 3;
  static const int passwordStrengthStrong = 4;
  static const int passwordStrengthVeryStrong = 5;
  
  static const List<String> passwordCategories = [
    'Réseaux sociaux',
    'Email',
    'Banque',
    'Shopping',
    'Travail',
    'Divertissement',
    'Santé',
    'Éducation',
    'Autre',
  ];
}

class AppAssets {
  static const String logo = 'assets/images/logo.png';
  static const String placeholder = 'assets/images/placeholder.png';
}