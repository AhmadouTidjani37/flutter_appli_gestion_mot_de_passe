class PasswordEntry {
  int? id;
  int userId;
  String serviceName;
  String serviceIcon;
  String username;
  String originalPassword;  
  String md5Hash;          
  String? notes;
  String category;
  bool isFavorite;
  DateTime createdAt;
  DateTime updatedAt;
  int? strength;

  PasswordEntry({
    this.id,
    required this.userId,
    required this.serviceName,
    this.serviceIcon = 'default',
    required this.username,
    required this.originalPassword,
    required this.md5Hash,
    this.notes,
    this.category = 'Autre',
    this.isFavorite = false,
    required this.createdAt,
    required this.updatedAt,
    this.strength,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'serviceName': serviceName,
      'serviceIcon': serviceIcon,
      'username': username,
      'originalPassword': originalPassword,
      'md5Hash': md5Hash,
      'notes': notes,
      'category': category,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'strength': strength,
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      userId: map['userId'],
      serviceName: map['serviceName'],
      serviceIcon: map['serviceIcon'],
      username: map['username'],
      originalPassword: map['originalPassword'],
      md5Hash: map['md5Hash'],
      notes: map['notes'],
      category: map['category'],
      isFavorite: map['isFavorite'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
      strength: map['strength'],
    );
  }

  Map<String, dynamic> toJson() => toMap();
  
  factory PasswordEntry.fromJson(Map<String, dynamic> json) => PasswordEntry.fromMap(json);
}