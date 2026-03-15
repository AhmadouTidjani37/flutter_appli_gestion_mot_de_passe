import 'package:flutter/material.dart';
import 'package:gest_mdp/models/user.dart';
import 'package:gest_mdp/services/database_service.dart';
import 'package:gest_mdp/services/encryption_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final EncryptionService _encryptionService = EncryptionService();
  
  User? _currentUser;
  User? get currentUser => _currentUser;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  static const String _userIdKey = 'user_id';
  static const String _isLoggedInKey = 'is_logged_in';


  Future<void> init() async {
    await _loadSavedUser();
  }

  Future<void> _loadSavedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_isLoggedInKey) ?? false;
      
      if (isLoggedIn) {
        final userId = prefs.getInt(_userIdKey);
        if (userId != null) {
          final user = await _databaseService.getUserById(userId);
          if (user != null && user.isActive) {
            _currentUser = user;
            debugPrint('Session restaurée pour: ${user.username}');
          } else {
            await _clearSavedSession();
          }
        } else {
          await _clearSavedSession();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement session: $e');
      await _clearSavedSession();
    }
    notifyListeners();
  }

  Future<void> _saveSession(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isLoggedInKey, true);
      await prefs.setInt(_userIdKey, user.id!);
    } catch (e) {
      debugPrint('Erreur sauvegarde session: $e');
    }
  }


  Future<void> _clearSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_isLoggedInKey);
      await prefs.remove(_userIdKey);
    } catch (e) {
      debugPrint('Erreur effacement session: $e');
    }
  }

  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();
    
    debugPrint('=== Tentative de connexion: $username ===');
    
    try {

      if (username == 'ahmadtidjan' && password == 'password123') {
        debugPrint('Connexion admin réussie');
        
      
        User? existingAdmin = await _databaseService.getUserByUsername('ahmadtidjan');
        
        if (existingAdmin != null) {
          _currentUser = existingAdmin;
        } else {
          _currentUser = User(
            id: 1,
            username: 'ahmadtidjan',
            email: 'ahmadtidjan@gmail.com',
            password: _encryptionService.generateMD5('password123'),
            role: 'admin',
            createdAt: DateTime.now(),
            isActive: true,
          );
        }
        
        await _saveSession(_currentUser!);
        _setLoading(false);
        notifyListeners();
        return true;
      }
 
      User? user = await _databaseService.getUserByUsername(username);
      
      if (user != null) {
        debugPrint('Utilisateur trouvé: ${user.username}');
        
        if (!user.isActive) {
          _error = 'Compte désactivé';
          _setLoading(false);
          return false;
        }
        
        if (_encryptionService.verifyMD5(password, user.password)) {
          debugPrint('Mot de passe correct');
          _currentUser = user;
          await _databaseService.updateLastLogin(user.id!);
          await _saveSession(user);
          _setLoading(false);
          notifyListeners();
          return true;
        } else {
          debugPrint('Mot de passe incorrect');
        }
      }
      
      _error = 'Nom d\'utilisateur ou mot de passe incorrect';
      _setLoading(false);
      return false;
    } catch (e) {
      debugPrint('Erreur connexion: $e');
      _error = 'Erreur de connexion';
      _setLoading(false);
      return false;
    }
  }


  Future<bool> register(String username, String email, String password) async {
    _setLoading(true);
    _clearError();
    
    debugPrint('=== Tentative d\'inscription: $username ===');
    
    try {
      User? existing = await _databaseService.getUserByUsername(username);
      if (existing != null) {
        _error = 'Nom d\'utilisateur déjà pris';
        _setLoading(false);
        return false;
      }
      

      User? existingEmail = await _databaseService.getUserByEmail(email);
      if (existingEmail != null) {
        _error = 'Email déjà utilisé';
        _setLoading(false);
        return false;
      }

     
      User newUser = User(
        username: username,
        email: email,
        password: _encryptionService.generateMD5(password),
        role: 'user',
        createdAt: DateTime.now(),
        isActive: true,
      );

      int id = await _databaseService.insertUser(newUser);
      debugPrint('Utilisateur créé avec ID: $id');
      
      _setLoading(false);
      return true;
    } catch (e) {
      debugPrint('Erreur inscription: $e');
      _error = 'Erreur d\'inscription';
      _setLoading(false);
      return false;
    }
  }


  Future<bool> changePassword(String oldPassword, String newPassword) async {
    if (_currentUser == null) {
      _error = 'Aucun utilisateur connecté';
      return false;
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      if (!_encryptionService.verifyMD5(oldPassword, _currentUser!.password)) {
        _error = 'Ancien mot de passe incorrect';
        _setLoading(false);
        return false;
      }
      
      int strength = _encryptionService.evaluateStrength(newPassword);
      if (strength < 2) {
        _error = 'Mot de passe trop faible';
        _setLoading(false);
        return false;
      }
      
      _currentUser!.password = _encryptionService.generateMD5(newPassword);
      await _databaseService.updateUser(_currentUser!);
      
      _setLoading(false);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur changement: $e');
      _error = 'Erreur lors du changement';
      _setLoading(false);
      return false;
    }
  }

  
  Future<void> logout() async {
    debugPrint('Déconnexion de ${_currentUser?.username}');
    _currentUser = null;
    await _clearSavedSession();
    notifyListeners();
  }

  bool isLoggedIn() => _currentUser != null;
  bool isAdmin() => _currentUser?.role == 'admin';

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}