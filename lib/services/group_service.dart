import 'dart:convert';
import 'package:http/http.dart' as http;

class GroupService {
  final String baseUrl;
  GroupService({required this.baseUrl});

  // Récupérer tous les groupes dont l'utilisateur est membre
  Future<List<Map<String, dynamic>>> getUserGroups(String token) async {
    final url = Uri.parse('$baseUrl/groupes'); // Endpoint backend à créer pour les groupes d'un utilisateur
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur récupération groupes utilisateur: ${response.body}');
    }
  }

  // Récupérer les membres d’un groupe
  Future<List<Map<String, dynamic>>> getGroupMembers(String token, int groupId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      if (data.containsKey('membres')) {
        return List<Map<String, dynamic>>.from(data['membres']);
      }
      return [];
    } else {
      throw Exception('Erreur récupération membres: ${response.body}');
    }
  }
  // GroupService.dart
  Future<List<Map<String, dynamic>>> getAvailableGroups(String token) async {
    final url = Uri.parse('$baseUrl/groupes/available');
    final response = await http.get(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur récupération groupes disponibles');
    }
  }

  Future<void> joinGroup(String token, int groupId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/join');
    final response = await http.post(url, headers: {"Authorization": "Bearer $token"});

    if (response.statusCode == 200) {
      return;
    } else {
      final body = jsonDecode(response.body);

      throw Exception(body['message'] ?? 'Impossible de rejoindre le groupe');
    }
  }
  Future<void> deleteGroup(String token, int groupId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId');
    final response = await http.delete(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression groupe: ${response.body}');
    }
  }


  Future<void> leaveGroup(String token, int groupId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/leave');
    final response = await http.post(url, headers: {"Authorization": "Bearer $token"});
    if (response.statusCode != 200) {
      throw Exception('Erreur quitter groupe');
    }
  }


  // Récupérer tous les utilisateurs pour ajout (créateur uniquement)
  Future<List<Map<String, dynamic>>> getAllUsers(String token) async {
    final url = Uri.parse('$baseUrl/users');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      throw Exception('Erreur récupération utilisateurs: ${response.body}');
    }
  }

  // Créer un groupe
  Future<Map<String, dynamic>> createGroup(String token, String nom, String? description) async {
    final url = Uri.parse('$baseUrl/groupes');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "nom": nom,
        "description": description ?? "",
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erreur création groupe: ${response.body}');
    }
  }


  // Ajouter un membre par user_id (créateur seulement côté backend)
  Future<void> addMember(String token, int groupId, int userId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/add-membre');
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"user_id": userId}));

    if (response.statusCode != 200) {
      throw Exception('Erreur ajout membre: ${response.body}');
    }
  }

  // Retirer un membre par user_id (créateur ou membre lui-même)
  Future<void> removeMember(String token, int groupId, int userId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/remove-membre');
    final response = await http.post(url,
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({"user_id": userId}));

    if (response.statusCode != 200) {
      throw Exception('Erreur suppression membre: ${response.body}');
    }
  }
}
