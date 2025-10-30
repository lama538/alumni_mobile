import 'dart:convert';
import 'package:http/http.dart' as http;

class EventService {
  final String baseUrl;
  EventService({required this.baseUrl});

  Future<List<Map<String, dynamic>>> getEvents(String token) async {
    final url = Uri.parse('$baseUrl/api/evenements');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded.containsKey('data')) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return List<Map<String, dynamic>>.from(decoded);
    } else {
      throw Exception(
        "Erreur lors de la récupération des événements : ${response.statusCode} - ${response.body}",
      );
    }
  }

  Future<http.Response> registerUser(int eventId, int userId, String token) async {
    final url = Uri.parse('$baseUrl/api/evenements/$eventId/register');
    final body = jsonEncode({"user_id": userId});

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: body,
    );

    return response; // ne lance pas d'exception ici
  }

}
