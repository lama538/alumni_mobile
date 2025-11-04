// lib/models/user.dart

class User {
  final int? id;
  final String name;
  final String email;
  final String role;
  final String? photo; // ✅ ajouté pour la messagerie

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] != null ? json['id'] as int : null,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      photo: json['photo'] != null
          ? (json['photo'].toString().startsWith('http')
          ? json['photo']
          : 'http://10.0.2.2:8000/storage/${json['photo']}')
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'photo': photo,
    };
  }
}

class LoginResponse {
  final String token;
  final User user;

  LoginResponse({
    required this.token,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      token: json['token'] ?? '',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'user': user.toJson(),
    };
  }
}
