import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user.dart';
import '../models/password_entry.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'gestion_mdp_v2.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

Future _onCreate(Database db, int version) async {
  await db.execute('''
    CREATE TABLE utilisateurs(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT NOT NULL DEFAULT 'user',
      createdAt TEXT NOT NULL,
      lastLogin TEXT,
      isActive INTEGER DEFAULT 1
    )
  ''');

  await db.execute('''
    CREATE TABLE mots_de_passe(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      userId INTEGER NOT NULL,
      serviceName TEXT NOT NULL,
      serviceIcon TEXT DEFAULT 'default',
      username TEXT NOT NULL,
      originalPassword TEXT NOT NULL,
      md5Hash TEXT NOT NULL,
      notes TEXT,
      category TEXT DEFAULT 'Autre',
      isFavorite INTEGER DEFAULT 0,
      createdAt TEXT NOT NULL,
      updatedAt TEXT NOT NULL,
      strength INTEGER,
      FOREIGN KEY (userId) REFERENCES utilisateurs (id) ON DELETE CASCADE
    )
  ''');

  await db.execute('CREATE INDEX idx_userId ON mots_de_passe(userId)');
  await db.execute('CREATE INDEX idx_service ON mots_de_passe(serviceName)');
  await db.execute('CREATE INDEX idx_category ON mots_de_passe(category)');

  await db.insert('utilisateurs', {
  'username': 'ahmadtidjan',
  'email': 'ahmadtidjan@gmail.com',
  'password': '5d41402abc4b2a76b9719d911017c592',
  'role': 'admin',
  'createdAt': DateTime.now().toIso8601String(),
  'isActive': 1,
});
}

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE mots_de_passe ADD COLUMN strength INTEGER');
    }
  }


  Future<int> insertUser(User user) async {
    Database db = await database;
    return await db.insert('utilisateurs', user.toMap());
  }

  Future<User?> getUserByUsername(String username) async {
    Database db = await database;
    var maps = await db.query(
      'utilisateurs',
      where: 'username = ?',
      whereArgs: [username],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserByEmail(String email) async {
    Database db = await database;
    var maps = await db.query(
      'utilisateurs',
      where: 'email = ?',
      whereArgs: [email],
    );
    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

 Future<User?> getUserById(int id) async {
  Database db = await database;
  var maps = await db.query(
    'utilisateurs',
    where: 'id = ?',
    whereArgs: [id],
  );
  if (maps.isNotEmpty) {
    return User.fromMap(maps.first);
  }
  return null;
}
  Future<List<User>> getAllUsers() async {
    Database db = await database;
    var maps = await db.query('utilisateurs', orderBy: 'username ASC');
    return List.generate(maps.length, (i) => User.fromMap(maps[i]));
  }

  Future<int> updateUser(User user) async {
    Database db = await database;
    return await db.update(
      'utilisateurs',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> updateLastLogin(int userId) async {
    Database db = await database;
    return await db.update(
      'utilisateurs',
      {'lastLogin': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<int> deleteUser(int id) async {
    Database db = await database;
    return await db.delete(
      'utilisateurs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> toggleUserStatus(int id, bool isActive) async {
    Database db = await database;
    return await db.update(
      'utilisateurs',
      {'isActive': isActive ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> insertPassword(PasswordEntry password) async {
    Database db = await database;
    return await db.insert('mots_de_passe', password.toMap());
  }

  Future<List<PasswordEntry>> getPasswordsByUser(int userId) async {
    Database db = await database;
    var maps = await db.query(
      'mots_de_passe',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'isFavorite DESC, serviceName ASC',
    );
    return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
  }

  Future<List<PasswordEntry>> getFavoritePasswords(int userId) async {
    Database db = await database;
    var maps = await db.query(
      'mots_de_passe',
      where: 'userId = ? AND isFavorite = 1',
      whereArgs: [userId],
      orderBy: 'serviceName ASC',
    );
    return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
  }

  Future<List<PasswordEntry>> searchPasswords(int userId, String query) async {
    Database db = await database;
    var maps = await db.query(
      'mots_de_passe',
      where: 'userId = ? AND (serviceName LIKE ? OR username LIKE ? OR category LIKE ?)',
      whereArgs: [userId, '%$query%', '%$query%', '%$query%'],
      orderBy: 'serviceName ASC',
    );
    return List.generate(maps.length, (i) => PasswordEntry.fromMap(maps[i]));
  }

  Future<PasswordEntry?> getPasswordById(int id) async {
    Database db = await database;
    var maps = await db.query(
      'mots_de_passe',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return PasswordEntry.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updatePassword(PasswordEntry password) async {
    Database db = await database;
    return await db.update(
      'mots_de_passe',
      password.toMap(),
      where: 'id = ?',
      whereArgs: [password.id],
    );
  }

  Future<int> toggleFavorite(int id, bool isFavorite) async {
    Database db = await database;
    return await db.update(
      'mots_de_passe',
      {'isFavorite': isFavorite ? 1 : 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deletePassword(int id) async {
    Database db = await database;
    return await db.delete(
      'mots_de_passe',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllUserPasswords(int userId) async {
    Database db = await database;
    return await db.delete(
      'mots_de_passe',
      where: 'userId = ?',
      whereArgs: [userId],
    );
  }


  Future<Map<String, dynamic>> getUserStats(int userId) async {
    Database db = await database;
    
    var totalCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM mots_de_passe WHERE userId = ?',
      [userId]
    )) ?? 0;
    
    var favoriteCount = Sqflite.firstIntValue(await db.rawQuery(
      'SELECT COUNT(*) FROM mots_de_passe WHERE userId = ? AND isFavorite = 1',
      [userId]
    )) ?? 0;
    
    var categories = await db.rawQuery(
      'SELECT category, COUNT(*) as count FROM mots_de_passe WHERE userId = ? GROUP BY category',
      [userId]
    );
    
    var lastAdded = await db.query(
      'mots_de_passe',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
      limit: 1,
    );
    
    return {
      'total': totalCount,
      'favorites': favoriteCount,
      'categories': categories,
      'lastAdded': lastAdded.isNotEmpty ? PasswordEntry.fromMap(lastAdded.first) : null,
    };
  }
}