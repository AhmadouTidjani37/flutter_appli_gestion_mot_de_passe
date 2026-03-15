import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/database_service.dart';
import '../../models/password_entry.dart';
import 'add_password_screen.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PasswordDetailScreen extends StatefulWidget {
  final PasswordEntry password;

  const PasswordDetailScreen({super.key, required this.password});

  @override
  State<PasswordDetailScreen> createState() => _PasswordDetailScreenState();
}

class _PasswordDetailScreenState extends State<PasswordDetailScreen> {
  bool _obscurePassword = true;
  bool _showMD5 = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.password.serviceName,style: TextStyle(
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
        actions: [
          IconButton(
            icon: Icon(
              widget.password.isFavorite ? Icons.favorite : Icons.favorite_border,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editPassword,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: Container(
        height:MediaQuery.of(context).size.height,
        width:MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
         image:DecorationImage(
          image:AssetImage("assets/bg_img.png"),
          fit:BoxFit.cover
         )
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
             
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.password.category).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getCategoryIcon(widget.password.category),
                    size: 50,
                    color: _getCategoryColor(widget.password.category),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(widget.password.category).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.password.category,
                    style: TextStyle(
                      color: _getCategoryColor(widget.password.category),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),

           
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Service',
                        widget.password.serviceName,
                        Icons.web,
                      ),
                      const Divider(),
                      _buildInfoRow(
                        'Identifiant',
                        widget.password.username,
                        Icons.person,
                        onTap: () => _copyToClipboard(widget.password.username, 'Identifiant copié'),
                      ),
                      const Divider(),
                      _buildPasswordRow(),
                      const Divider(),
                      _buildMD5Row(),
                      if (widget.password.notes != null && widget.password.notes!.isNotEmpty) ...[
                        const Divider(),
                        _buildInfoRow(
                          'Notes',
                          widget.password.notes!,
                          Icons.note,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

             
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Créé le: ${_formatDate(widget.password.createdAt)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.update, size: 16, color: Colors.grey),
                          const SizedBox(width: 8),
                          Text(
                            'Modifié le: ${_formatDate(widget.password.updatedAt)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Force du mot de passe',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          ...List.generate(5, (index) {
                            return Expanded(
                              child: Container(
                                height: 10,
                                margin: const EdgeInsets.only(right: 5),
                                decoration: BoxDecoration(
                                  color: index < (widget.password.strength ?? 0)
                                      ? _getStrengthColor(widget.password.strength ?? 0)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getStrengthText(widget.password.strength ?? 0),
                        style: TextStyle(
                          color: _getStrengthColor(widget.password.strength ?? 0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildInfoRow(String label, String value, IconData icon, {VoidCallback? onTap, String? copyMessage}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: Colors.blue, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.copy, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.lock, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Mot de passe original',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _obscurePassword ? '••••••••' : widget.password.originalPassword,
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              _copyToClipboard(widget.password.originalPassword, 'Mot de passe copié');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMD5Row() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.fingerprint, color: Colors.orange, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Hash MD5',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showMD5 
                      ? widget.password.md5Hash 
                      : '${widget.password.md5Hash.substring(0, 8)}...',
                  style: const TextStyle(
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(_showMD5 ? Icons.visibility_off : Icons.visibility),
            onPressed: () {
              setState(() {
                _showMD5 = !_showMD5;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            onPressed: () {
              _copyToClipboard(widget.password.md5Hash, 'Hash MD5 copié');
            },
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    
    bool newValue = !widget.password.isFavorite;
    await databaseService.toggleFavorite(widget.password.id!, newValue);
    
    setState(() {
      widget.password.isFavorite = newValue;
    });

    Fluttertoast.showToast(
      msg: newValue ? 'Ajouté aux favoris' : 'Retiré des favoris',
      backgroundColor: newValue ? Colors.green : Colors.orange,
    );
  }

  void _editPassword() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddPasswordScreen(
          passwordToEdit: widget.password,
        ),
      ),
    ).then((_) => Navigator.pop(context, true));
  }

  Future<void> _confirmDelete() async {
    bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmation'),
        content: const Text(
          'Voulez-vous vraiment supprimer ce mot de passe ?'
        ),
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
      final databaseService = Provider.of<DatabaseService>(context, listen: false);
      await databaseService.deletePassword(widget.password.id!);
      
      Fluttertoast.showToast(
        msg: 'Mot de passe supprimé',
        backgroundColor: Colors.green,
      );
      Navigator.pop(context, true);
    }
  }

  void _copyToClipboard(String text, String message) {
  
    Fluttertoast.showToast(
      msg: message,
      backgroundColor: Colors.green,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} à ${date.hour}:${date.minute}';
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Réseaux sociaux':
        return Colors.blue;
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

  Color _getStrengthColor(int strength) {
    if (strength <= 1) return Colors.red;
    if (strength <= 3) return Colors.orange;
    return Colors.green;
  }

  String _getStrengthText(int strength) {
    if (strength <= 1) return 'Faible';
    if (strength <= 3) return 'Moyen';
    return 'Fort';
  }
}