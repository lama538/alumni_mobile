import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/ user.dart';
import '../models/message_model.dart';
import '../models/notification_model.dart';
import '../models/offre_model.dart';
import '../models/group_message.dart';
import 'package:shared_preferences/shared_preferences.dart';




class ApiService {
  static const String baseUrl = "http://127.0.0.1:8000/api"; // Pour Android Emulator

  // -----------------------------
  // 🔑 Authentification
  // -----------------------------

  // Inscription
  static Future<http.Response> register(
      String name, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/register');
    final body = jsonEncode({
      'name': name,
      'email': email,
      'password': password,
      'password_confirmation': password,
      'role': role,
    });

    final response = await http.post(
      url,
      body: body,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    print('Request body: $body');
    print('Response: ${response.body}');
    return response;
  }

  // Connexion (renvoie le token et l'utilisateur)
  static Future<LoginResponse> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/login');
    final body = jsonEncode({'email': email, 'password': password});

    final response = await http.post(
      url,
      body: body,
      headers: {
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Stocker le token pour l’utiliser plus tard
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userToken', data['token']);

      return LoginResponse.fromJson(data);
    } else {
      throw Exception("Erreur de connexion: ${response.body}");
    }
  }


  // Récupérer profil général (User)
  static Future<User> getProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      return User.fromJson(jsonData['user']);
    } else {
      throw Exception("Erreur lors de la récupération du profil");
    }
  }

  // Mot de passe oublié
  static Future<http.Response> forgotPassword(String email) async {
    final url = Uri.parse('$baseUrl/forgot-password');
    final body = jsonEncode({'email': email});
    return await http.post(
      url,
      body: body,
      headers: {"Content-Type": "application/json"},
    );
  }

  // -----------------------------
  // ✅ Profils Alumni
  // -----------------------------

  // Récupérer le profil Alumni
  static Future<http.Response> getAlumniProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });
    print('Get profile response: ${response.body}');
    return response;
  }

  // Créer un profil Alumni
  static Future<http.Response> createProfile(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(data),
    );
    print('Create profile response: ${response.body}');
    return response;
  }

  // Mettre à jour le profil Alumni
  static Future<http.Response> updateProfile(String token, Map<String, dynamic> data) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(data),
    );
    print('Update profile response: ${response.body}');
    return response;
  }

  // Supprimer le profil Alumni
  static Future<http.Response> deleteProfile(String token) async {
    final url = Uri.parse('$baseUrl/profile');
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );
    print('Delete profile response: ${response.body}');
    return response;
  }


  // -----------------------------
  // 💬 Messagerie interne
  // -----------------------------

  static Future<List<AppMessage>> getMessages(String token) async {
    final url = Uri.parse('$baseUrl/messages');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppMessage.fromJson(json)).toList();
    } else {
      throw Exception("Erreur get messages: ${response.body}");
    }
  }


  static Future<AppMessage> sendMessage(String token, int receiverId, String contenu) async {
    final url = Uri.parse('$baseUrl/messages');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "receiver_id": receiverId,
        "contenu": contenu,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return AppMessage.fromJson(data);
    } else {
      throw Exception("Erreur send message: ${response.body}");
    }
  }


  // --- 📦 NOTIFICATIONS ---

  // Récupérer notifications
  static Future<List<AppNotification>> getNotifications(String token) async {
    final url = Uri.parse('$baseUrl/notifications');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppNotification.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get notifications: ${response.body}');
    }
  }

  // Marquer notification comme lue
  static Future<void> markNotificationRead(String token, String id) async {
    final url = Uri.parse('$baseUrl/notifications/mark-read/$id');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Erreur mark notification read: ${response.body}');
    }
  }

  // Supprimer toutes les notifications lues
  static Future<void> clearReadNotifications(String token) async {
    final url = Uri.parse('$baseUrl/notifications/clear-read');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Erreur clear notifications: ${response.body}');
    }
  }

  static Future<List<Offre>> getOffres() async {
    final response = await http.get(
      Uri.parse('$baseUrl/offres'),
      headers: {"Accept": "application/json"},
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((e) => Offre.fromJson(e)).toList();
    } else {
      throw Exception("Erreur lors de la récupération des offres");
    }
  }
// -----------------------------
// 📅 Gestion des événements
// -----------------------------

// Récupérer tous les événements
  static Future<List<dynamic>> getEvents(String token) async {
    final url = Uri.parse('$baseUrl/evenements');
    final response = await http.get(url, headers: {
      "Authorization": "Bearer $token",
      "Accept": "application/json",
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data;
    } else {
      throw Exception("Erreur lors de la récupération des événements: ${response.body}");
    }
  }

// Créer un nouvel événement
  static Future<dynamic> createEvent(String token, Map<String, dynamic> eventData) async {
    final url = Uri.parse('$baseUrl/evenements');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur lors de la création de l'événement: ${response.body}");
    }
  }

// -----------------------------
// 📅 Gestion des événements
// -----------------------------

// Modifier un événement existant
  static Future<dynamic> updateEvent(String token, int eventId, Map<String, dynamic> eventData) async {
    final url = Uri.parse('$baseUrl/evenements/$eventId');
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode(eventData),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Erreur lors de la modification de l'événement: ${response.body}");
    }
  }

// Supprimer un événement
  static Future<void> deleteEvent(String token, int eventId) async {
    final url = Uri.parse('$baseUrl/evenements/$eventId');
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode != 200) {
      throw Exception("Erreur lors de la suppression de l'événement: ${response.body}");
    }
  }
// Dans ApiService
// Inscrire un utilisateur à un événement
  static Future<http.Response> registerUser(int eventId, int userId, String token) async {
    final url = Uri.parse('$baseUrl/evenements/$eventId/register');
    final body = jsonEncode({"user_id": userId}); // ou selon ton API Laravel
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: body,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return response;
    } else {
      throw Exception("Erreur lors de l'inscription à l'événement: ${response.body}");
    }
  }
  static Future<List<Map<String, dynamic>>> getEventParticipants(
      String token, int eventId) async {
    final url = Uri.parse('$baseUrl/evenements/$eventId/participants');
    final response = await http.get(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      },
    );

    print('Participants API response: ${response.body}'); // 🔍 Debug

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Si c'est un array direct
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }

      // Si c'est un objet avec "data"
      if (decoded is Map && decoded.containsKey('data')) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }

      // Sinon, renvoyer liste vide pour éviter les crashs
      return [];
    } else {
      throw Exception(
        "Erreur lors du chargement des participants : "
            "${response.statusCode} - ${response.body}",
      );
    }
  }



// Récupérer les messages d’un groupe
  static Future<List<GroupMessage>> getGroupMessages(String token, int groupId) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/messages');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => GroupMessage.fromJson(json)).toList();
    } else {
      throw Exception('Erreur récupération messages groupe: ${response.body}');
    }
  }

// Envoyer un message dans un groupe
  // Envoyer un message dans un groupe (texte, image, vidéo, etc.)
  static Future<GroupMessage> sendGroupMessage(
      String token,
      int groupId,
      String message, {
        String? mediaPath, // chemin du fichier média (image, vidéo, audio)
        String? mediaType, // type du média : "image", "video", "audio"
      }) async {
    final url = Uri.parse('$baseUrl/groupes/$groupId/messages');

    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['message'] = message;

    // Ajouter le type de média si fourni
    if (mediaType != null) {
      request.fields['media_type'] = mediaType;
    }

    // Ajouter le fichier média s’il existe
    if (mediaPath != null && mediaPath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('media', mediaPath));
    }

    // Envoyer la requête
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Sécurisation au cas où le message serait null
      if (data['message'] == null) data['message'] = '';

      return GroupMessage.fromJson(data);
    } else {
      throw Exception('Erreur envoi message: ${response.body}');
    }
  }





}
