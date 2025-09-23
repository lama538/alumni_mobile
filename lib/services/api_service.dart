import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/ user.dart';

class ApiService {
  static const String baseUrl = "http://10.0.2.2:8000/api"; // Pour Android Emulator

  // Inscription
  static Future<http.Response> register(
      String name, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/register');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
    return await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );
  }

  // Connexion
  static Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final body = jsonEncode({'email': email, 'password': password});
    return await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );
  }

  // Récupérer profil
  static Future<User> getProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });
    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception("Erreur lors de la récupération du profil");
    }
  }

  // ✅ Mot de passe oublié
  static Future<http.Response> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');
    final body = jsonEncode({'email': email});
    return await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );
  }
}
