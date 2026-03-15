import 'package:flutter/material.dart';
import 'package:gest_mdp/models/user.dart';
import 'package:gest_mdp/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class UserManagementScreen extends StatefulWidget {
  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<User> _users = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);

    try {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      _users = await databaseService.getAllUsers();
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Erreur: $e',
        backgroundColor: Colors.red,
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<User> get _filteredUsers {
    if (_searchQuery.isEmpty) return _users;
    return _users.where((user) =>
      user.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      user.email.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gest-Utilisateurs',style: TextStyle(color:Colors.white, fontSize:19,fontWeight:FontWeight.bold),),
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
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Container(
            color: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Rechercher un utilisateur...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = _filteredUsers[index];
                  return _buildUserCard(user);
                },
              ),
            ),
    );
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: user.isActive
              ? Colors.green.shade100
              : Colors.grey.shade100,
          child: Text(
            user.username[0].toUpperCase(),
            style: TextStyle(
              color: user.isActive ? Colors.green : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          user.username,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(user.email),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: user.role == 'admin'
                ? Colors.orange.shade100
                : Colors.purple.shade100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            user.role,
            style: TextStyle(
              color: user.role == 'admin' ? Colors.orange : Colors.purple,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('ID', '${user.id}'),
                _buildInfoRow('Email', user.email),
                _buildInfoRow(
                  'Membre depuis',
                  '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}',
                ),
                if (user.lastLogin != null)
                  _buildInfoRow(
                    'Dernière connexion',
                    '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}',
                  ),
                _buildInfoRow(
                  'Statut',
                  user.isActive ? 'Actif' : 'Inactif',
                  color: user.isActive ? Colors.green : Colors.red,
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    if (user.role != 'admin')
                      ElevatedButton.icon(
                        onPressed: () => _promoteToAdmin(user),
                        icon: Icon(Icons.admin_panel_settings),
                        label: Text('Admin'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                        ),
                      ),
                    if (user.username != 'ahmadtidjan')
                      ElevatedButton.icon(
                        onPressed: () => _toggleUserStatus(user),
                        icon: Icon(user.isActive ? Icons.block : Icons.check),
                        label: Text(user.isActive ? 'Désactiver' : 'Activer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: user.isActive ? Colors.red : Colors.green,
                        ),
                      ),
                    if (user.username != 'ahmadtidjan')
                      ElevatedButton.icon(
                        onPressed: () => _deleteUser(user),
                        icon: Icon(Icons.delete),
                        label: Text('Supprimer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleUserStatus(User user) async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    bool newStatus = !user.isActive;
    await databaseService.toggleUserStatus(user.id!, newStatus);
    
    setState(() {
      user.isActive = newStatus;
    });

    Fluttertoast.showToast(
      msg: newStatus ? 'Utilisateur activé' : 'Utilisateur désactivé',
      backgroundColor: newStatus ? Colors.green : Colors.orange,
    );
  }

  Future<void> _promoteToAdmin(User user) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text(
          'Voulez-vous promouvoir ${user.username} au rôle d\'administrateur ?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Promouvoir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      user.role = 'admin';
      await databaseService.updateUser(user);
      
      setState(() {});

      Fluttertoast.showToast(
        msg: 'Utilisateur promu administrateur',
        backgroundColor: Colors.green,
      );
    }
  }

  Future<void> _deleteUser(User user) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmation'),
        content: Text(
          'Voulez-vous vraiment supprimer l\'utilisateur ${user.username} ?\n'
          'Toutes ses données seront perdues.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      
      await databaseService.deleteUser(user.id!);
      
      setState(() {
        _users.remove(user);
      });

      Fluttertoast.showToast(
        msg: 'Utilisateur supprimé',
        backgroundColor: Colors.green,
      );
    }
  }
}