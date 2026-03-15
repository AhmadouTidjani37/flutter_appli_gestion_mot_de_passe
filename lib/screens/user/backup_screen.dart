import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/google_drive_service.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  List<Map<String, dynamic>> _backups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);

    try {
      final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      
      if (!googleDriveService.isConnected) {
        await googleDriveService.connect();
      }

      _backups = await googleDriveService.listBackups(authService.currentUser!.username);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final googleDriveService = Provider.of<GoogleDriveService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegarde Google Drive',style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),),
        flexibleSpace: Container(
        height:MediaQuery.of(context).size.height,
        width:MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
         image:DecorationImage(
          image:AssetImage("assets/bg_img.png"),
          fit:BoxFit.cover
         )
        )
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade50,
              Colors.white,
            ],
          ),
        ),
        child: Column(
          children: [
       
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: googleDriveService.isConnected
                        ? Colors.green.shade100
                        : Colors.grey.shade100,
                    child: Icon(
                      googleDriveService.isConnected
                          ? Icons.cloud_done
                          : Icons.cloud_off,
                      color: googleDriveService.isConnected
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          googleDriveService.isConnected
                              ? 'Connecté à Google Drive'
                              : 'Non connecté',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (googleDriveService.isConnected)
                          Text(googleDriveService.accountEmail ?? ''),
                      ],
                    ),
                  ),
                  if (!googleDriveService.isConnected)
                    ElevatedButton(
                      onPressed: () async {
                        bool connected = await googleDriveService.connect();
                        if (connected) {
                          setState(() {});
                          _loadBackups();
                        }
                      },
                      child: const Text('Connecter'),
                    ),
                ],
              ),
            ),

          
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: googleDriveService.isConnected
                          ? () => _createBackup(authService.currentUser!.username)
                          : null,
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Nouvelle sauvegarde'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: googleDriveService.isConnected
                          ? _loadBackups
                          : null,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualiser'),
                    ),
                  ),
                ],
              ),
            ),

     
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _backups.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _backups.length,
                          itemBuilder: (context, index) {
                            final backup = _backups[index];
                            return _buildBackupCard(backup);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupCard(Map<String, dynamic> backup) {
    DateTime createdTime = DateTime.parse(backup['createdTime']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.backup, color: Colors.purple),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Sauvegarde du ${_formatDate(createdTime)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Taille: ${_formatSize(backup['size'])}'),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _restoreBackup(backup['id']),
                  icon: const Icon(Icons.cloud_download),
                  label: const Text('Restaurer'),
                ),
                const SizedBox(width: 10),
                TextButton.icon(
                  onPressed: () => _deleteBackup(backup['id']),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  label: Text('Supprimer', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune sauvegarde',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Créez votre première sauvegarde',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(String username) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Création de la sauvegarde...'),
          ],
        ),
      ),
    );

    try {
      final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final passwords = await databaseService.getPasswordsByUser(
        authService.currentUser!.id!,
      );

      bool success = await googleDriveService.backupPasswords(
        passwords,
        authService.currentUser!.id!,
        username,
      );

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          Fluttertoast.showToast(
            msg: 'Sauvegarde réussie',
            backgroundColor: Colors.green,
          );
          _loadBackups();
        } else {
          Fluttertoast.showToast(
            msg: 'Échec de la sauvegarde',
            backgroundColor: Colors.red,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        Fluttertoast.showToast(
          msg: 'Erreur: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  Future<void> _restoreBackup(String fileId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'La restauration remplacera tous vos mots de passe actuels. '
          'Voulez-vous continuer ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      Fluttertoast.showToast(
        msg: 'Fonctionnalité à implémenter',
        backgroundColor: Colors.orange,
      );
    }
  }

  Future<void> _deleteBackup(String fileId) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text('Voulez-vous vraiment supprimer cette sauvegarde ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
        bool success = await googleDriveService.deleteBackup(fileId);

        if (success) {
          Fluttertoast.showToast(
            msg: 'Sauvegarde supprimée',
            backgroundColor: Colors.green,
          );
          _loadBackups();
        } else {
          Fluttertoast.showToast(
            msg: 'Échec de la suppression',
            backgroundColor: Colors.red,
          );
        }
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Erreur: $e',
          backgroundColor: Colors.red,
        );
      }
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _formatSize(int? size) {
    if (size == null) return 'Inconnu';
    
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}