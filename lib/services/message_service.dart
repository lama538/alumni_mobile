import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ user.dart';
import '../models/message_model.dart';
import 'api_service.dart';

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
  static Future<List<AppMessage>> getSentMessages(String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/sent');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.map((json) => AppMessage.fromJson(json)).toList();
    } else {
      throw Exception('Erreur get sent messages: ${response.body}');
    }
  }

  // ✅ Récupérer tous les messages avec un utilisateur
  static Future<List<AppMessage>> getMessages(String token, int otherUserId) async {
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

  // ✅ Envoyer un message texte ou média
  static Future<AppMessage> sendMessageWithMedia(
      String token, int receiverId, String contenu, File? media,
      {int? messageId}) async {
    final prefs = await SharedPreferences.getInstance();
    final senderId = prefs.getInt('user_id');
    if (senderId == null) throw Exception("Aucun utilisateur connecté trouvé");

    final url = Uri.parse('${ApiService.baseUrl}/messages');

    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['sender_id'] = senderId.toString()
      ..fields['receiver_id'] = receiverId.toString()
      ..fields['contenu'] = contenu.isNotEmpty ? contenu : '';

    if (messageId != null) {
      request.fields['message_id'] = messageId.toString(); // Pour édition
    }

    // 🔹 Ajouter le fichier média si présent
    if (media != null) {
      final fileName = media.path.split('/').last;
      request.files.add(await http.MultipartFile.fromPath(
        'media',
        media.path,
        filename: fileName,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      return AppMessage.fromJson(data);
    } else {
      throw Exception('Erreur send message with media: ${response.body}');
    }
  }

  // ✅ Envoyer uniquement un message texte
  static Future<AppMessage> sendMessage(String token, int receiverId, String contenu) async {
    return sendMessageWithMedia(token, receiverId, contenu, null);
  }

  // ✅ Modifier un message existant
  static Future<AppMessage> editMessage(String token, int messageId, String contenu, File? media) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/$messageId');

    var request = http.MultipartRequest('POST', url)
      ..headers['Authorization'] = 'Bearer $token'
      ..headers['Accept'] = 'application/json'
      ..fields['contenu'] = contenu;

    if (media != null) {
      final fileName = media.path.split('/').last;
      request.files.add(await http.MultipartFile.fromPath(
        'media',
        media.path,
        filename: fileName,
      ));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return AppMessage.fromJson(data);
    } else {
      throw Exception('Erreur edit message: ${response.body}');
    }
  }

  // ✅ Supprimer un message
  static Future<void> deleteMessage(String token, int messageId) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/$messageId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Erreur delete message: ${response.body}');
    }
  }

  // ✅ Récupérer les messages reçus
  static Future<List<AppMessage>> getReceivedMessages(String token) async {
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

  // ✅ Marquer les messages comme lus
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

  // ✅ Récupérer la boîte de réception
  static Future<List<Map<String, dynamic>>> getInbox(String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/inbox');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else {
      throw Exception('Erreur get inbox: ${response.body}');
    }
  }
  static Future<void> deleteConversation(String token, int otherUserId) async {
    final url = Uri.parse('${ApiService.baseUrl}/messages/conversation/$otherUserId');
    final response = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (response.statusCode != 200) {
      throw Exception('Erreur delete conversation: ${response.body}');
    }
  }
}
