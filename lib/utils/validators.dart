class Validators {

  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom d\'utilisateur est requis';
    }
    if (value.length < 3) {
      return 'Le nom d\'utilisateur doit contenir au moins 3 caractères';
    }
    if (value.length > 20) {
      return 'Le nom d\'utilisateur ne peut pas dépasser 20 caractères';
    }
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Caractères autorisés: lettres, chiffres et _';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Email invalide';
    }
    return null;
  }

 
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    if (value.length > 50) {
      return 'Le mot de passe ne peut pas dépasser 50 caractères';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Veuillez confirmer le mot de passe';
    }
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    return null;
  }


  static String? validateServiceName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom du service est requis';
    }
    return null;
  }

 
  static String? validateIdentifier(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'identifiant est requis';
    }
    return null;
  }
}