import 'dart:convert';
import 'package:http/http.dart' as http;

class ActualiteService {
  final String baseUrl;
  ActualiteService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> getActualitesWithToken(String token) async {
    final url = Uri.parse('$baseUrl/api/actualites');
    final response = await http.get(url, headers: {
      "Accept": "application/json",
      "Authorization": "Bearer $token",
    });

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    } else if (response.statusCode == 401) {
      throw Exception("Non authentifié (token invalide ou expiré).");
    } else {
      throw Exception("Erreur chargement actualités (${response.statusCode}) : ${response.body}");
    }
  }

  Future<void> createActualite(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/api/actualites');
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        body: jsonEncode(data));

    if (response.statusCode != 201) {
      throw Exception("Erreur création actualité : ${response.body}");
    }
  }
}
