import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/password_entry.dart';
import 'package:fluttertoast/fluttertoast.dart';

class GoogleDriveService extends ChangeNotifier {
  static final GoogleDriveService _instance = GoogleDriveService._internal();
  factory GoogleDriveService() => _instance;
  GoogleDriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveFileScope,
      drive.DriveApi.driveAppdataScope,
      'email',
      'profile',
    ],
  );

  drive.DriveApi? _driveApi;
  
  bool _isConnected = false;
  bool get isConnected => _isConnected;
  
  String? _accountEmail;
  String? get accountEmail => _accountEmail;
  
  String? _error;
  String? get error => _error;

  static const String _prefsIsConnected = 'google_drive_connected';
  static const String _prefsAccountEmail = 'google_drive_email';
  static const String _prefsAccountId = 'google_drive_account_id';

  Future<void> init() async {
    await _loadSavedConnection();
  }

  Future<void> _loadSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedConnected = prefs.getBool(_prefsIsConnected) ?? false;
      final savedEmail = prefs.getString(_prefsAccountEmail);
      
      if (savedConnected && savedEmail != null) {
        debugPrint('Tentative de restauration connexion Google Drive: $savedEmail');
        
        try {
          final account = await _googleSignIn.signInSilently();
          
          if (account != null && account.email == savedEmail) {
            final authHeaders = await account.authHeaders;
            final client = GoogleAuthClient(authHeaders);
            _driveApi = drive.DriveApi(client);
            _isConnected = true;
            _accountEmail = account.email;
            
            debugPrint('Connexion Google Drive restaurée pour: ${account.email}');
            
            try {
              await _driveApi!.about.get();
              debugPrint('Test de connexion réussi');
            } catch (e) {
              debugPrint('Test de connexion échoué, déconnexion: $e');
              await _clearSavedConnection();
              _isConnected = false;
              _accountEmail = null;
            }
          } else {
            debugPrint('Impossible de restaurer, déconnexion');
            await _clearSavedConnection();
          }
        } catch (e) {
          debugPrint('Erreur restauration: $e');
          await _clearSavedConnection();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement connexion Google Drive: $e');
    }
    notifyListeners();
  }

  // Sauvegarder l'état de connexion
  Future<void> _saveConnection(String email, {String? accountId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsIsConnected, true);
      await prefs.setString(_prefsAccountEmail, email);
      if (accountId != null) {
        await prefs.setString(_prefsAccountId, accountId);
      }
      debugPrint('État Google Drive sauvegardé pour: $email');
    } catch (e) {
      debugPrint('Erreur sauvegarde état Google Drive: $e');
    }
  }

  // Effacer l'état de connexion sauvegardé
  Future<void> _clearSavedConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsIsConnected);
      await prefs.remove(_prefsAccountEmail);
      await prefs.remove(_prefsAccountId);
      debugPrint('État Google Drive effacé');
    } catch (e) {
      debugPrint('Erreur effacement état Google Drive: $e');
    }
  }

  // Connexion
  Future<bool> connect() async {
    _error = null;
    
    try {
      debugPrint('Tentative de connexion à Google Drive...');
      
      if (_isConnected && _driveApi != null) {
        debugPrint('Déjà connecté');
        return true;
      }
      
      GoogleSignInAccount? currentAccount = _googleSignIn.currentUser;
      
      if (currentAccount == null) {
        currentAccount = await _googleSignIn.signInSilently();
      }
      
      if (currentAccount == null) {
        currentAccount = await _googleSignIn.signIn();
      }
      
      if (currentAccount != null) {
        debugPrint('Connexion réussie pour: ${currentAccount.email}');
        
        final authHeaders = await currentAccount.authHeaders;
        final client = GoogleAuthClient(authHeaders);
        _driveApi = drive.DriveApi(client);
        _isConnected = true;
        _accountEmail = currentAccount.email;
        
        await _saveConnection(
          currentAccount.email,
          accountId: currentAccount.id,
        );
        
        try {
          await _driveApi!.about.get();
          debugPrint('Test de connexion réussi');
        } catch (e) {
          debugPrint('Test de connexion échoué: $e');
        }
        
        notifyListeners();
        
        Fluttertoast.showToast(
          msg: 'Connecté à Google Drive: ${currentAccount.email}',
          backgroundColor: Colors.green,
        );
        
        return true;
      } else {
        debugPrint('Connexion annulée par l\'utilisateur');
        _error = 'Connexion annulée';
        return false;
      }
    } catch (e) {
      debugPrint('Erreur de connexion détaillée: $e');
      _error = 'Erreur de connexion: $e';
      
      Fluttertoast.showToast(
        msg: 'Erreur de connexion: Vérifiez votre connexion internet',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      
      return false;
    }
  }


  Future<void> disconnect() async {
    try {
      await _googleSignIn.signOut();
      _driveApi = null;
      _isConnected = false;
      _accountEmail = null;
      
      await _clearSavedConnection();
      
      notifyListeners();
      debugPrint('Déconnexion de Google Drive réussie');
      
      Fluttertoast.showToast(
        msg: 'Déconnecté de Google Drive',
        backgroundColor: Colors.orange,
      );
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

 
  Future<bool> ensureConnected() async {
    if (!_isConnected) {
      return await connect();
    }
    return true;
  }

  Future<bool> backupPasswords(List<PasswordEntry> passwords, int userId, String username) async {
    if (!await ensureConnected()) {
      Fluttertoast.showToast(
        msg: 'Veuillez vous connecter à Google Drive',
        backgroundColor: Colors.red,
      );
      return false;
    }

    try {
      Map<String, dynamic> backupData = {
        'userId': userId,
        'username': username,
        'date': DateTime.now().toIso8601String(),
        'version': '1.0',
        'passwords': passwords.map((p) => p.toJson()).toList(),
      };

      String jsonData = jsonEncode(backupData);
      List<int> dataBytes = utf8.encode(jsonData);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'backup_${username}_$timestamp.json';
      
      debugPrint('Création du fichier de backup: $fileName');
      
      final file = drive.File()
        ..name = fileName
        ..parents = ['appDataFolder']
        ..mimeType = 'application/json'
        ..properties = {
          'userId': userId.toString(),
          'username': username,
          'timestamp': timestamp.toString(),
        };

      final media = drive.Media(
        Stream.fromIterable(dataBytes.map((e) => [e])),
        dataBytes.length,
      );

      final createdFile = await _driveApi!.files.create(
        file,
        uploadMedia: media,
      );

      debugPrint('Backup créé avec succès: ${createdFile.id}');
      
      Fluttertoast.showToast(
        msg: 'Sauvegarde réussie sur Google Drive',
        backgroundColor: Colors.green,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur détaillée backup: $e');
      
      String errorMessage = 'Erreur backup';
      if (e.toString().contains('network')) {
        errorMessage = 'Erreur réseau';
      } else if (e.toString().contains('permission')) {
        errorMessage = 'Permission refusée';
      }
      
      Fluttertoast.showToast(
        msg: errorMessage,
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      
      return false;
    }
  }

  Future<List<PasswordEntry>?> restorePasswords(int userId, String username) async {
    if (!await ensureConnected()) {
      return null;
    }

    try {
      debugPrint('Recherche des backups pour $username...');
      
      final response = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'backup_${username}_' and trashed = false",
        orderBy: 'createdTime desc',
        pageSize: 10,
      );

      if (response.files == null || response.files!.isEmpty) {
        debugPrint('Aucun backup trouvé pour $username');
        
        Fluttertoast.showToast(
          msg: 'Aucune sauvegarde trouvée',
          backgroundColor: Colors.orange,
        );
        
        return null;
      }

      debugPrint('${response.files!.length} backup(s) trouvé(s)');

      final latestBackup = response.files!.first;
      debugPrint('Backup le plus récent: ${latestBackup.name} (${latestBackup.createdTime})');
      
      final fileContent = await _driveApi!.files.get(
        latestBackup.id!,
        downloadOptions: drive.DownloadOptions.fullMedia,
      ) as drive.Media?;
      
      if (fileContent == null) {
        debugPrint('Impossible de télécharger le fichier');
        return null;
      }

      final stream = fileContent.stream;
      final bytes = await stream.fold<List<int>>(
        [],
        (previous, element) => previous + element,
      );
      
      final jsonData = utf8.decode(bytes);
      final Map<String, dynamic> backupMap = jsonDecode(jsonData);

      if (backupMap['userId'] != userId || backupMap['username'] != username) {
        debugPrint('Backup pour un autre utilisateur');
        
        Fluttertoast.showToast(
          msg: 'Ce backup ne vous appartient pas',
          backgroundColor: Colors.orange,
        );
        
        return null;
      }

      List<dynamic> passwordsJson = backupMap['passwords'];
      return passwordsJson.map((json) => PasswordEntry.fromJson(json)).toList();
      
    } catch (e) {
      debugPrint('Erreur détaillée restauration: $e');
      
      Fluttertoast.showToast(
        msg: 'Erreur restauration',
        backgroundColor: Colors.red,
        toastLength: Toast.LENGTH_LONG,
      );
      
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> listBackups(String username) async {
    if (!_isConnected) {
      return [];
    }

    try {
      final response = await _driveApi!.files.list(
        spaces: 'appDataFolder',
        q: "name contains 'backup_${username}_' and trashed = false",
        orderBy: 'createdTime desc',
        pageSize: 20,
      );

      if (response.files == null) return [];

      return response.files!.map((file) => {
        'id': file.id,
        'name': file.name,
        'createdTime': file.createdTime?.toIso8601String(),
        'size': file.size,
      }).toList();
      
    } catch (e) {
      debugPrint('Erreur liste backups: $e');
      return [];
    }
  }

  Future<bool> deleteBackup(String fileId) async {
    if (!_isConnected) {
      return false;
    }

    try {
      await _driveApi!.files.delete(fileId);
      
      Fluttertoast.showToast(
        msg: 'Sauvegarde supprimée',
        backgroundColor: Colors.green,
      );
      
      return true;
    } catch (e) {
      debugPrint('Erreur suppression backup: $e');
      
      Fluttertoast.showToast(
        msg: 'Erreur suppression',
        backgroundColor: Colors.red,
      );
      
      return false;
    }
  }

  Map<String, dynamic> getConnectionInfo() {
    return {
      'isConnected': _isConnected,
      'email': _accountEmail,
    };
  }
}

class GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}