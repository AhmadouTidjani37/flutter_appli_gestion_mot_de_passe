import 'package:flutter/material.dart';
import 'package:gest_mdp/models/password_entry.dart';
import 'package:gest_mdp/screens/user/password_detail_screen.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/google_drive_service.dart';
import 'add_password_screen.dart';
import 'password_list_screen.dart';
import 'backup_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserDashboard extends StatefulWidget {
  const UserDashboard({super.key});

  @override
  State<UserDashboard> createState() => _UserDashboardState();
}

class _UserDashboardState extends State<UserDashboard> with AutomaticKeepAliveClientMixin {
  int _totalPasswords = 0;
  int _favoriteCount = 0;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  PasswordEntry? _lastAddedPassword;
  List<PasswordEntry> _recentPasswords = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    if (!mounted) return;
    
    setState(() => _isLoading = true);
    
    final authService = Provider.of<AuthService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    if (authService.currentUser != null && authService.currentUser!.id != null) {
      try {
        _stats = await databaseService.getUserStats(authService.currentUser!.id!);
        _lastAddedPassword = _stats['lastAdded'] as PasswordEntry?;
        

        final allPasswords = await databaseService.getPasswordsByUser(
          authService.currentUser!.id!,
        );
        _recentPasswords = allPasswords.take(3).toList();
        
        if (mounted) {
          setState(() {
            _totalPasswords = _stats['total'] ?? 0;
            _favoriteCount = _stats['favorites'] ?? 0;
            _isLoading = false;
          });
        }
      } catch (e) {
        debugPrint('Erreur chargement stats: $e');
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final authService = Provider.of<AuthService>(context);
    final googleDriveService = Provider.of<GoogleDriveService>(context);

    if (authService.currentUser == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Utilisateur non connecté',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                child: const Text('Retour à la connexion'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Gest-MDP',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        flexibleSpace: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg_img.png"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupScreen()),
              ).then((_) => _loadStats());
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (String value) async {
              switch (value) {
                case 'profile':
                  _showProfileDialog();
                  break;
                case 'password':
                  _showChangePasswordDialog();
                  break;
                case 'about':
                  _showAboutDialog();
                  break;
                case 'logout':
                  bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Déconnexion'),
                      content: const Text('Voulez-vous vraiment vous déconnecter ?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annuler'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Déconnexion'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && mounted) {
                    await authService.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: ListTile(
                  leading: Icon(Icons.person),
                  title: Text('Profil'),
                ),
              ),
              const PopupMenuItem(
                value: 'password',
                child: ListTile(
                  leading: Icon(Icons.lock),
                  title: Text('Changer mot de passe'),
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('À propos'),
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Déconnexion'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/bg_img.png"),
              fit: BoxFit.cover,
            ),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildUserHeader(authService),
                      const SizedBox(height: 20),
                      _buildStatsGrid(),
                      const SizedBox(height: 20),
                      _buildQuickActions(),
                      const SizedBox(height: 20),
                      if (_recentPasswords.isNotEmpty) _buildRecentPasswords(),
                      const SizedBox(height: 20),
                      _buildGoogleDriveSection(googleDriveService),
                    ],
                  ),
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
          ).then((_) => _loadStats());
        },
        child: const Icon(Icons.add, color:Colors.white),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildUserHeader(AuthService authService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.purple.shade100,
              child: Text(
                authService.currentUser?.username[0].toUpperCase() ?? 'U',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    authService.currentUser?.username ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    authService.currentUser?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Membre depuis ${_formatDate(authService.currentUser!.createdAt)}',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      children: [
        _buildStatCard(
          'Mots de passe',
          '$_totalPasswords',
          Icons.lock,
          Colors.purple,
        ),
        _buildStatCard(
          'Favoris',
          '$_favoriteCount',
          Icons.favorite,
          Colors.red,
        ),
        _buildStatCard(
          'Catégories',
          '${_stats['categories']?.length ?? 0}',
          Icons.category,
          Colors.orange,
        ),
        _buildStatCard(
          'Dernier ajout',
          _lastAddedPassword != null
              ? _lastAddedPassword!.serviceName
              : 'Aucun',
          Icons.access_time,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions rapides',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Ajouter',
                    Icons.add,
                    Colors.green,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
                      ).then((_) => _loadStats());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    'Voir tout',
                    Icons.list,
                    Colors.purple,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PasswordListScreen()),
                      ).then((_) => _loadStats());
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Favoris',
                    Icons.favorite,
                    Colors.red,
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PasswordListScreen(
                            showFavoritesOnly: true,
                          ),
                        ),
                      ).then((_) => _loadStats());
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildActionButton(
                    'Rechercher',
                    Icons.search,
                    Colors.purple,
                    () => _showSearchDialog(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    'Sync Drive',
                    Icons.cloud_sync,
                    Colors.purple,
                    () => _showBackupDialog(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPasswords() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Récents',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PasswordListScreen()),
                    );
                  },
                  child: const Text('Voir tout'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ..._recentPasswords.map((password) => _buildRecentPasswordItem(password)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPasswordItem(PasswordEntry password) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getCategoryColor(password.category).withOpacity(0.2),
        child: Icon(
          _getCategoryIcon(password.category),
          color: _getCategoryColor(password.category),
          size: 20,
        ),
      ),
      title: Text(password.serviceName),
      subtitle: Text(password.username),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (password.isFavorite)
            const Icon(Icons.favorite, color: Colors.red, size: 16),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordDetailScreen(password: password),
          ),
        ).then((_) => _loadStats());
      },
    );
  }

  Widget _buildGoogleDriveSection(GoogleDriveService googleDriveService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.cloud, color: Colors.purple),
                const SizedBox(width: 10),
                const Text(
                  'Google Drive',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (googleDriveService.isConnected) ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green.shade100,
                  child: Icon(
                    Icons.check,
                    color: Colors.green.shade700,
                  ),
                ),
                title: const Text('Connecté'),
                subtitle: Text(googleDriveService.accountEmail ?? ''),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _backupToDrive(),
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text('Sauvegarder'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _restoreFromDrive(),
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Restaurer'),
                    ),
                  ),
                ],
              ),
            ] else ...[
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: Icon(
                    Icons.cloud_off,
                    color: Colors.grey.shade700,
                  ),
                ),
                title: const Text('Non connecté'),
                subtitle: const Text('Connectez-vous pour sauvegarder vos mots de passe'),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  bool connected = await googleDriveService.connect();
                  if (connected && mounted) {
                    Fluttertoast.showToast(
                      msg: 'Connecté à Google Drive',
                      backgroundColor: Colors.green,
                    );
                    setState(() {});
                  }
                },
                icon: const Icon(Icons.login),
                label: const Text('Se connecter à Google Drive'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 45),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _backupToDrive() async {
    final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!googleDriveService.isConnected) {
      bool connected = await googleDriveService.connect();
      if (!connected) {
        Fluttertoast.showToast(
          msg: 'Impossible de se connecter à Google Drive',
          backgroundColor: Colors.red,
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Sauvegarde en cours...'),
          ],
        ),
      ),
    );

    try {
      final passwords = await databaseService.getPasswordsByUser(
        authService.currentUser!.id!,
      );

      bool success = await googleDriveService.backupPasswords(
        passwords,
        authService.currentUser!.id!,
        authService.currentUser!.username,
      );

      if (mounted) {
        Navigator.pop(context);

        if (success) {
          Fluttertoast.showToast(
            msg: 'Sauvegarde réussie sur Google Drive',
            backgroundColor: Colors.green,
          );
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

  Future<void> _restoreFromDrive() async {
    final googleDriveService = Provider.of<GoogleDriveService>(context, listen: false);
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    if (!googleDriveService.isConnected) {
      bool connected = await googleDriveService.connect();
      if (!connected) return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Restauration en cours...'),
          ],
        ),
      ),
    );

    try {
      final restoredPasswords = await googleDriveService.restorePasswords(
        authService.currentUser!.id!,
        authService.currentUser!.username,
      );

      if (mounted) {
        Navigator.pop(context);

        if (restoredPasswords != null && restoredPasswords.isNotEmpty) {
          bool? replace = await showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmation'),
              content: Text(
                'Voulez-vous remplacer vos ${restoredPasswords.length} mots de passe actuels par ceux de la sauvegarde ?'
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Remplacer'),
                ),
              ],
            ),
          );

          if (replace == true) {
            await databaseService.deleteAllUserPasswords(authService.currentUser!.id!);
            
            for (var password in restoredPasswords) {
              password.userId = authService.currentUser!.id!;
              await databaseService.insertPassword(password);
            }

            Fluttertoast.showToast(
              msg: 'Restauration réussie',
              backgroundColor: Colors.green,
            );
            _loadStats();
          }
        } else {
          Fluttertoast.showToast(
            msg: 'Aucune sauvegarde trouvée',
            backgroundColor: Colors.orange,
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

  void _showBackupDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Synchronisation Google Drive'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.cloud_upload, color: Colors.purple),
              title: const Text('Sauvegarder'),
              subtitle: const Text('Envoyer vers Google Drive'),
              onTap: () {
                Navigator.pop(context);
                _backupToDrive();
              },
            ),
            ListTile(
              leading: const Icon(Icons.cloud_download, color: Colors.green),
              title: const Text('Restaurer'),
              subtitle: const Text('Récupérer depuis Google Drive'),
              onTap: () {
                Navigator.pop(context);
                _restoreFromDrive();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  void _showProfileDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.purple.shade100,
              child: Text(
                authService.currentUser!.username[0].toUpperCase(),
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.purple.shade700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              authService.currentUser!.username,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(authService.currentUser!.email),
            const SizedBox(height: 10),
            Text(
              'Membre depuis: ${_formatDate(authService.currentUser!.createdAt)}',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 5),
            Text(
              'ID: ${authService.currentUser!.id}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          bool obscureOld = true;
          bool obscureNew = true;
          bool obscureConfirm = true;
          
          return AlertDialog(
            title: const Text('Changer mot de passe'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: oldPasswordController,
                    obscureText: obscureOld,
                    decoration: InputDecoration(
                      labelText: 'Ancien mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureOld ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            obscureOld = !obscureOld;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            obscureNew = !obscureNew;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: confirmController,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirmer',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            obscureConfirm = !obscureConfirm;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (newPasswordController.text != confirmController.text) {
                    Fluttertoast.showToast(
                      msg: 'Les mots de passe ne correspondent pas',
                      backgroundColor: Colors.red,
                    );
                    return;
                  }

                  bool success = await authService.changePassword(
                    oldPasswordController.text,
                    newPasswordController.text,
                  );

                  if (success && mounted) {
                    Navigator.pop(context);
                    Fluttertoast.showToast(
                      msg: 'Mot de passe changé avec succès',
                      backgroundColor: Colors.green,
                    );
                  } else {
                    Fluttertoast.showToast(
                      msg: authService.error ?? 'Erreur lors du changement',
                      backgroundColor: Colors.red,
                    );
                  }
                },
                child: const Text('Changer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('À propos'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock, size: 50, color: Colors.purple),
            const SizedBox(height: 20),
            const Text(
              'Gestionnaire de Mots de Passe',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Version 1.0.0'),
            const SizedBox(height: 10),
            const Text(
              'Application sécurisée pour gérer vos mots de passe '
              'avec cryptage et sauvegarde Google Drive.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              'Développéen Flutter',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechercher'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Service, identifiant...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PasswordListScreen(
                    searchQuery: value,
                  ),
                ),
              );
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (searchController.text.isNotEmpty) {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PasswordListScreen(
                      searchQuery: searchController.text,
                    ),
                  ),
                );
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Réseaux sociaux':
        return Colors.purple;
      case 'Email':
        return Colors.red;
      case 'Banque':
        return Colors.green;
      case 'Shopping':
        return Colors.orange;
      case 'Travail':
        return Colors.purple;
      case 'Divertissement':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Réseaux sociaux':
        return Icons.people;
      case 'Email':
        return Icons.email;
      case 'Banque':
        return Icons.account_balance;
      case 'Shopping':
        return Icons.shopping_cart;
      case 'Travail':
        return Icons.work;
      case 'Divertissement':
        return Icons.movie;
      default:
        return Icons.lock;
    }
  }
}