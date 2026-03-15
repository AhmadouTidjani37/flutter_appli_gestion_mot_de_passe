import 'package:flutter/material.dart';
import 'package:gest_mdp/models/password_entry.dart';
import 'package:gest_mdp/services/auth_service.dart';
import 'package:gest_mdp/services/database_service.dart';
import 'package:gest_mdp/services/encryption_service.dart';
import 'package:gest_mdp/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:fluttertoast/fluttertoast.dart';

class AddPasswordScreen extends StatefulWidget {
  final PasswordEntry? passwordToEdit;

  const AddPasswordScreen({super.key, this.passwordToEdit});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();
  
  String _selectedCategory = 'Autre';
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isFavorite = false;
  int _passwordStrength = 0;
  String _generatedMD5 = '';
  
  final List<String> _categories = const [
    'Réseaux sociaux',
    'Email',
    'Banque',
    'Shopping',
    'Travail',
    'Divertissement',
    'Autre',
  ];

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updateStrengthAndMD5);
    
    if (widget.passwordToEdit != null) {
      _serviceController.text = widget.passwordToEdit!.serviceName;
      _usernameController.text = widget.passwordToEdit!.username;
      _passwordController.text = widget.passwordToEdit!.originalPassword;
      _notesController.text = widget.passwordToEdit!.notes ?? '';
      _selectedCategory = widget.passwordToEdit!.category;
      _isFavorite = widget.passwordToEdit!.isFavorite;
      _generatedMD5 = widget.passwordToEdit!.md5Hash;
    }
  }

  void _updateStrengthAndMD5() {
    final encryptionService = Provider.of<EncryptionService>(context, listen: false);
    setState(() {
      _passwordStrength = encryptionService.evaluateStrength(_passwordController.text);
      if (_passwordController.text.isNotEmpty) {
        _generatedMD5 = encryptionService.generateMD5(_passwordController.text);
      } else {
        _generatedMD5 = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final encryptionService = Provider.of<EncryptionService>(context);
    final isEditing = widget.passwordToEdit != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifier' : 'Ajouter un mot de passe',style: TextStyle(
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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                
                Center(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.purple.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_outline,
                      size: 50,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

           
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        
                        TextFormField(
                          controller: _serviceController,
                          decoration: InputDecoration(
                            labelText: 'Service / Site web',
                            prefixIcon: const Icon(Icons.web),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le nom du service';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Identifiant / Email',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer l\'identifiant';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),

                        
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.refresh),
                                  onPressed: () {
                                    String generated = encryptionService.generatePassword();
                                    _passwordController.text = generated;
                                  },
                                ),
                                IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                              ],
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer le mot de passe';
                            }
                            return null;
                          },
                        ),

                    
                        if (_passwordController.text.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Row(
                              children: [
                                Text('Force: ${encryptionService.getStrengthText(_passwordStrength)}'),
                                const SizedBox(width: 10),
                                ...List.generate(5, (index) {
                                  return Icon(
                                    index < _passwordStrength
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: encryptionService.getStrengthColor(_passwordStrength),
                                    size: 20,
                                  );
                                }),
                              ],
                            ),
                          ),

                        
                        if (_generatedMD5.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(top: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Hash MD5 généré:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                SelectableText(
                                  _generatedMD5,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 15),

                      
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Catégorie',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 15),

                      
                        TextFormField(
                          controller: _notesController,
                          maxLines: 3,
                          decoration: InputDecoration(
                            labelText: 'Notes (optionnel)',
                            prefixIcon: const Icon(Icons.note),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),

                        
                        CheckboxListTile(
                          title: const Text('Ajouter aux favoris'),
                          value: _isFavorite,
                          onChanged: (value) {
                            setState(() {
                              _isFavorite = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: isEditing ? 'Mettre à jour' : 'Sauvegarder',
                  onPressed: () => _savePassword(encryptionService),
                  isLoading: _isLoading,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _savePassword(EncryptionService encryptionService) async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final databaseService = Provider.of<DatabaseService>(context, listen: false);

        String md5Hash = encryptionService.generateMD5(_passwordController.text);
        int strength = encryptionService.evaluateStrength(_passwordController.text);

        if (widget.passwordToEdit == null) {
        
          PasswordEntry newPassword = PasswordEntry(
            userId: authService.currentUser!.id!,
            serviceName: _serviceController.text,
            username: _usernameController.text,
            originalPassword: _passwordController.text,
            md5Hash: md5Hash,
            notes: _notesController.text.isNotEmpty ? _notesController.text : null,
            category: _selectedCategory,
            isFavorite: _isFavorite,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            strength: strength,
          );

          await databaseService.insertPassword(newPassword);
          
          Fluttertoast.showToast(
            msg: 'Mot de passe ajouté avec succès',
            backgroundColor: Colors.green,
          );
        } else {
          
          widget.passwordToEdit!.serviceName = _serviceController.text;
          widget.passwordToEdit!.username = _usernameController.text;
          widget.passwordToEdit!.originalPassword = _passwordController.text;
          widget.passwordToEdit!.md5Hash = md5Hash;
          widget.passwordToEdit!.notes = _notesController.text;
          widget.passwordToEdit!.category = _selectedCategory;
          widget.passwordToEdit!.isFavorite = _isFavorite;
          widget.passwordToEdit!.updatedAt = DateTime.now();
          widget.passwordToEdit!.strength = strength;

          await databaseService.updatePassword(widget.passwordToEdit!);
          
          Fluttertoast.showToast(
            msg: 'Mot de passe mis à jour',
            backgroundColor: Colors.green,
          );
        }

        Navigator.pop(context, true);
      } catch (e) {
        Fluttertoast.showToast(
          msg: 'Erreur: $e',
          backgroundColor: Colors.red,
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _serviceController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    _passwordController.removeListener(_updateStrengthAndMD5);
    super.dispose();
  }
}