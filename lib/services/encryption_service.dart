import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';

class EncryptionService extends ChangeNotifier {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();


  String generateMD5(String password) {
    return md5.convert(utf8.encode(password)).toString();
  }


  bool verifyMD5(String password, String hash) {
    return generateMD5(password) == hash;
  }

  String generatePassword({int length = 12}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  int evaluateStrength(String password) {
    if (password.isEmpty) return 0;
    
    int score = 0;
    
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    
    return score;
  }

  String getStrengthText(int score) {
    switch (score) {
      case 0: 
      case 1: return 'Faible';
      case 2: 
      case 3: return 'Moyen';
      case 4: 
      case 5: return 'Fort';
      default: return 'Inconnu';
    }
  }

  Color getStrengthColor(int score) {
    if (score <= 1) return Colors.red;
    if (score <= 3) return Colors.orange;
    return Colors.green;
  }
}