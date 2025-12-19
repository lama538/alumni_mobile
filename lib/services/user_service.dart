import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final String baseUrl = "http://127.0.0.1:8000/api";

  // 🔹 Récupérer la liste selon type (etudiants, alumni, entreprise, all)
  Future<List<dynamic>> getUsersByType(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    if (token == null) {
      throw Exception("Token introuvable");
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/type/$type'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors du chargement des utilisateurs");
    }

    return json.decode(response.body);
  }

  // 🔹 Bloquer / Débloquer un utilisateur
  Future<bool?> toggleBlock(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('userToken');

    final response = await http.post(
      Uri.parse('$baseUrl/users/$userId/block-toggle'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    print('Status code: ${response.statusCode}');
    print('Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // retourne l'état réel renvoyé par le serveur
      return data['isBlocked'] == true;
    }

    return null; // en cas d'erreur
  }

}
