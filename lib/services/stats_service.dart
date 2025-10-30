import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  final String baseUrl = "http://10.0.2.2:8000/api";

  // Méthode principale pour récupérer les stats
  Future<Map<String, dynamic>> fetchStats() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('userToken');

    if (token == null) {
      throw Exception("Token utilisateur introuvable. Veuillez vous reconnecter.");
    }

    final response = await _getWithToken('/stats', token);

    // Si 401 Unauthorized, tenter de rafraîchir le token
    if (response.statusCode == 401) {
      final newToken = await _refreshToken();
      if (newToken != null) {
        prefs.setString('userToken', newToken);
        return fetchStats(); // retry avec le nouveau token
      } else {
        throw Exception("Session expirée. Veuillez vous reconnecter.");
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception(
          "Erreur ${response.statusCode}: ${response.body}");
    }
  }

  // Méthode helper pour GET avec token
  Future<http.Response> _getWithToken(String path, String token) {
    return http.get(
      Uri.parse('$baseUrl$path'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
  }

  // Méthode pour rafraîchir le token
  Future<String?> _refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refreshToken');

    if (refreshToken == null) return null;

    final response = await http.post(
      Uri.parse('$baseUrl/refresh-token'),
      headers: {'Accept': 'application/json'},
      body: {'refresh_token': refreshToken},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['access_token']; // Assure-toi que ton backend retourne bien 'access_token'
    }

    return null; // Échec du refresh
  }
}
