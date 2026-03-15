import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gest_mdp/models/user.dart';
import 'package:gest_mdp/screens/admin/user_management_screen.dart';
import 'package:gest_mdp/services/auth_service.dart';
import 'package:gest_mdp/services/database_service.dart';
import 'package:provider/provider.dart';

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  List<User> _users = [];
  bool _isLoading = true;
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _users = await databaseService.getAllUsers();
      
      int totalUsers = _users.length;
      int activeUsers = _users.where((u) => u.isActive).length;
      int adminCount = _users.where((u) => u.role == 'admin').length;

      setState(() {
        _stats = {
          'total': totalUsers,
          'active': activeUsers,
          'inactive': totalUsers - activeUsers,
          'admins': adminCount,
          'users': totalUsers - adminCount,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Administration',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert),
            itemBuilder: (context) => [
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profil'),
                  onTap: () => _showProfileDialog(),
                ),
              ),
              PopupMenuItem(
                child: ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Déconnexion'),
                  onTap: () async {
                    await authService.logout();
                    if (mounted) {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
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
            : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                   
                    Card(
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
                              child: const Icon(
                                Icons.admin_panel_settings,
                                size: 30,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Administrateur',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(authService.currentUser?.username ?? ''),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      children: [
                        _buildStatCard(
                          'Utilisateurs',
                          '${_stats['total']}',
                          Icons.people,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Actifs',
                          '${_stats['active']}',
                          Icons.check_circle,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Inactifs',
                          '${_stats['inactive']}',
                          Icons.cancel,
                          Colors.red,
                        ),
                        _buildStatCard(
                          'Admins',
                          '${_stats['admins']}',
                          Icons.admin_panel_settings,
                          Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    Card(
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
                              'Gestion',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.purple.shade100,
                                child: const Icon(Icons.people, color: Colors.purple),
                              ),
                              title: const Text('Gérer les utilisateurs'),
                              subtitle: Text('${_stats['total']} utilisateurs'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => UserManagementScreen(),
                                  ),
                                ).then((_) => _loadData());
                              },
                            ),
                            const Divider(),
                            ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green.shade100,
                                child: const Icon(Icons.settings, color: Colors.green),
                              ),
                              title: const Text('Paramètres système'),
                              subtitle: const Text('Configuration générale'),
                              trailing: const Icon(Icons.arrow_forward_ios),
                              onTap: () {
                                _showSystemSettings();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    Card(
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
                              'Derniers utilisateurs',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            ..._users.take(5).map((user) => ListTile(
                              leading: CircleAvatar(
                                backgroundColor: user.isActive
                                    ? Colors.green.shade100
                                    : Colors.grey.shade100,
                                child: Text(
                                  user.username[0].toUpperCase(),
                                  style: TextStyle(
                                    color: user.isActive
                                        ? Colors.green
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              title: Text(user.username),
                              subtitle: Text(user.email),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: user.role == 'admin'
                                      ? Colors.orange.shade100
                                      : Colors.purple.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  user.role,
                                  style: TextStyle(
                                    color: user.role == 'admin'
                                        ? Colors.orange
                                        : Colors.purple,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showProfileDialog() {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Profil Administrateur'),
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
            const Text(
              'Rôle: Administrateur',
              style: TextStyle(color: Colors.orange),
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

  void _showSystemSettings() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Paramètres système'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Politique de mots de passe'),
              subtitle: const Text('Configurer la force minimale'),
              onTap: () {
                Navigator.pop(context);
                _showPasswordPolicyDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.backup),
              title: const Text('Sauvegarde automatique'),
              subtitle: const Text('Configurer les sauvegardes'),
              onTap: () {
                Navigator.pop(context);
                _showBackupSettingsDialog();
              },
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

  void _showPasswordPolicyDialog() {
    int minLength = 8;
    bool requireUppercase = true;
    bool requireNumbers = true;
    bool requireSpecialChars = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Politique de mots de passe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Longueur minimale',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  setState(() {
                    minLength = int.tryParse(value) ?? 8;
                  });
                },
              ),
              const SizedBox(height: 10),
              CheckboxListTile(
                title: const Text('Exiger des majuscules'),
                value: requireUppercase,
                onChanged: (value) {
                  setState(() {
                    requireUppercase = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Exiger des chiffres'),
                value: requireNumbers,
                onChanged: (value) {
                  setState(() {
                    requireNumbers = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Exiger des caractères spéciaux'),
                value: requireSpecialChars,
                onChanged: (value) {
                  setState(() {
                    requireSpecialChars = value ?? false;
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                Fluttertoast.showToast(
                  msg: 'Paramètres sauvegardés',
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }

  void _showBackupSettingsDialog() {
    bool autoBackup = false;
    String frequency = 'quotidienne';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sauvegarde automatique'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Activer la sauvegarde automatique'),
                value: autoBackup,
                onChanged: (value) {
                  setState(() {
                    autoBackup = value;
                  });
                },
              ),
              if (autoBackup) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: frequency,
                  decoration: const InputDecoration(
                    labelText: 'Fréquence',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'quotidienne', child: Text('Quotidienne')),
                    DropdownMenuItem(value: 'hebdomadaire', child: Text('Hebdomadaire')),
                    DropdownMenuItem(value: 'mensuelle', child: Text('Mensuelle')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      frequency = value!;
                    });
                  },
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                
                Fluttertoast.showToast(
                  msg: 'Paramètres sauvegardés',
                  backgroundColor: Colors.green,
                );
                Navigator.pop(context);
              },
              child: const Text('Sauvegarder'),
            ),
          ],
        ),
      ),
    );
  }
}