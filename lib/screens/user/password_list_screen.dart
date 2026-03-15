import 'package:flutter/material.dart';
import 'package:gest_mdp/models/password_entry.dart';
import 'package:gest_mdp/screens/user/add_password_screen.dart';
import 'package:gest_mdp/screens/user/password_detail_screen.dart';
import 'package:gest_mdp/services/auth_service.dart';
import 'package:gest_mdp/services/database_service.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shimmer/shimmer.dart';

class PasswordListScreen extends StatefulWidget {
  final bool showFavoritesOnly;
  final String? searchQuery;

  const PasswordListScreen({
    super.key,
    this.showFavoritesOnly = false,
    this.searchQuery,
  });

  @override
  State<PasswordListScreen> createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  List<PasswordEntry> _passwords = [];
  bool _isLoading = true;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final databaseService = Provider.of<DatabaseService>(context, listen: false);

      List<PasswordEntry> loadedPasswords;

      if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
        loadedPasswords = await databaseService.searchPasswords(
          authService.currentUser!.id!,
          widget.searchQuery!,
        );
      } else if (widget.showFavoritesOnly) {
        loadedPasswords = await databaseService.getFavoritePasswords(
          authService.currentUser!.id!,
        );
      } else {
        loadedPasswords = await databaseService.getPasswordsByUser(
          authService.currentUser!.id!,
        );
      }

      setState(() {
        _passwords = loadedPasswords;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      Fluttertoast.showToast(
        msg: 'Erreur de chargement: $e',
        backgroundColor: Colors.red,
      );
    }
  }

  List<PasswordEntry> get _filteredPasswords {
    if (_selectedCategory == null || _selectedCategory == 'Toutes') {
      return _passwords;
    }
    return _passwords.where((p) => p.category == _selectedCategory).toList();
  }

  Set<String> get _categories {
    Set<String> cats = {'Toutes'};
    _passwords.forEach((p) => cats.add(p.category));
    return cats;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.searchQuery != null
              ? 'Résultats recherche'
              : widget.showFavoritesOnly
                  ? 'Favoris'
                  : 'Mes mots de passe',style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        ),
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
        bottom: _passwords.isNotEmpty && widget.searchQuery == null
            ? PreferredSize(
                preferredSize: const Size.fromHeight(60),
                child: Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: DropdownButton<String>(
                    value: _selectedCategory ?? 'Toutes',
                    isExpanded: true,
                    items: _categories.map((category) {
                      return DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                ),
              )
            : null,
      ),
      body: _isLoading
          ? _buildShimmerLoading()
          : _passwords.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadPasswords,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredPasswords.length,
                    itemBuilder: (context, index) {
                      final password = _filteredPasswords[index];
                      return _buildPasswordCard(password);
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddPasswordScreen()),
          ).then((_) => _loadPasswords());
        },
        child: const Icon(Icons.add,color: Colors.white,),
        backgroundColor: Colors.purple,
      ),
    );
  }

  Widget _buildPasswordCard(PasswordEntry password) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PasswordDetailScreen(password: password),
            ),
          ).then((_) => _loadPasswords());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _getCategoryColor(password.category).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getCategoryIcon(password.category),
                  color: _getCategoryColor(password.category),
                ),
              ),
              const SizedBox(width: 12),

              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            password.serviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (password.isFavorite)
                          const Icon(Icons.favorite, color: Colors.red, size: 18),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      password.username,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(password.category).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            password.category,
                            style: TextStyle(
                              fontSize: 10,
                              color: _getCategoryColor(password.category),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'MD5: ${password.md5Hash.substring(0, 8)}...',
                            style: const TextStyle(
                              fontSize: 10,
                              fontFamily: 'monospace',
                              color: Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: 80,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 150,
                          height: 12,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 20),
          Text(
            widget.searchQuery != null
                ? 'Aucun résultat trouvé'
                : widget.showFavoritesOnly
                    ? 'Aucun favori pour le moment'
                    : 'Aucun mot de passe enregistré',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.searchQuery != null
                ? 'Essayez d\'autres termes de recherche'
                : widget.showFavoritesOnly
                    ? 'Ajoutez des mots de passe en favoris'
                    : 'Appuyez sur + pour ajouter votre premier mot de passe',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
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