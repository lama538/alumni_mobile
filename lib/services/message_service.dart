import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ user.dart';
import '../models/message_model.dart';
import 'api_service.dart';
import 'package:flutter/material.dart';


class MessageService {
  // ✅ Récupérer tous les utilisateurs
  static Future<List<User>> getUsers(String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/users');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get users: ${response.body}');
    }
  }

  // ✅ Récupérer tous les messages entre l'utilisateur connecté et un destinataire
  static Future<List<AppMessage>> getMessages(String token, int otherUserId) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getInt('user_id');
    if (currentUserId == null) throw Exception("Aucun utilisateur connecté trouvé");

    final url = Uri.parse('${ApiService.baseUrl}/messages/with/$otherUserId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppMessage.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get messages: ${response.body}');
    }
  }


  // ✅ Envoyer un message
  static Future<AppMessage> sendMessage(String token, int receiverId, String contenu) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getInt('user_id'); // ID utilisateur connecté
    if (senderId == null) throw Exception("Aucun utilisateur connecté trouvé");

    final url = Uri.parse('${ApiService.baseUrl}/messages');

    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
        "Accept": "application/json",
      },
      body: jsonEncode({
        "sender_id": senderId,
        "receiver_id": receiverId,
        "contenu": contenu,
      }),
    );

    debugPrint("sendMessage response: ${response.statusCode} -> ${response.body}");

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      // Vérification que tous les champs nécessaires existent
      if (data['id'] == null || data['sender_id'] == null || data['receiver_id'] == null || data['contenu'] == null || data['created_at'] == null) {
        throw Exception("Réponse du serveur invalide: $data");
      }

      return AppMessage.fromJson(data);
    } else {
      throw Exception("Erreur send message: ${response.body}");
    }
  }


  static Future<List<AppMessage>> getReceivedMessages(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception("Aucun utilisateur connecté trouvé");

    //final url = Uri.parse('${ApiService.baseUrl}/messages/received');
    //final url = Uri.parse('${ApiService.baseUrl}/messages/received?receiver_id=$userId');
    final url = Uri.parse('${ApiService.baseUrl}/messages/received');


    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppMessage.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get messages: ${response.body}');
    }
  }

  static Future<void> markMessagesAsRead(String token, int senderId) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/read/$senderId');
    final response = await http.post(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });
    if (response.statusCode != 200) {
      throw Exception('Erreur mark messages as read: ${response.body}');
    }
  }

  static Future<List<AppMessage>> getMessagesWithUser(
      String token, int userId) async {

    final url = Uri.parse('${ApiService.baseUrl}/messages/received?sender_id=$userId');
    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppMessage.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get messages: ${response.body}');
    }
  }

  // ✅ Récupérer la boîte de réception (expéditeurs + nombre de messages non lus)
  static Future<List<Map<String, dynamic>>> getInbox(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) throw Exception("Aucun utilisateur connecté trouvé");

    final url = Uri.parse('${ApiService.baseUrl}/messages/inbox');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      // On retourne une liste de maps contenant : sender_id, sender_name, unread_count, etc.
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erreur get inbox: ${response.body}');
    }
  }




}
