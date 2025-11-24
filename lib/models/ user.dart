class User {
  final int? id;
  final String name;
  final String email;
  final String role;
  String? photo; // ✅ rendue modifiable (enlève "final")

  User({
    this.id,
    required this.name,
    required this.email,
    required this.role,
    this.photo,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? photoPath;

    if (json['photo'] != null) {
      final rawPhoto = json['photo'].toString();
      photoPath = rawPhoto.startsWith('http')
          ? rawPhoto
          : 'http://10.0.2.2:8000/storage/$rawPhoto';
    }

    return User(
      id: json['id'] != null ? json['id'] as int : null,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? '',
      photo: photoPath,
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
