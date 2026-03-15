class User {
  int? id;
  String username;
  String email;
  String password;
  String role;
  DateTime createdAt;
  DateTime? lastLogin;
  bool isActive;

  User({
    this.id,
    required this.username,
    required this.email,
    required this.password,
    required this.role,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password': password,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastLogin': lastLogin?.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
      lastLogin: map['lastLogin'] != null 
          ? DateTime.parse(map['lastLogin']) 
          : null,
      isActive: map['isActive'] == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();
  
  factory User.fromJson(Map<String, dynamic> json) => User.fromMap(json);
}