import 'dart:convert';

class AppNotification {
  final String id;
  final String type;
  final String title;
  final String body;
  final String? sender;
  final DateTime createdAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.sender,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> dataMap = {};

    // Laravel renvoie parfois 'data' en String, parfois en Map
    if (json['data'] != null) {
      if (json['data'] is String) {
        try {
          dataMap = jsonDecode(json['data']);
        } catch (_) {
          dataMap = {};
        }
      } else if (json['data'] is Map) {
        dataMap = Map<String, dynamic>.from(json['data']);
      }
    }

    // Récupérer l'expéditeur
    String? sender;
    if (dataMap['sender'] != null) {
      sender = dataMap['sender'].toString();
    } else if (dataMap['user'] != null && dataMap['user']['name'] != null) {
      sender = dataMap['user']['name'].toString();
    }

    // Récupérer le contenu réel selon plusieurs champs possibles
    String body = '';
    if (dataMap['body'] != null) {
      body = dataMap['body'].toString();
    } else if (dataMap['message'] != null) {
      body = dataMap['message'].toString();
    } else if (dataMap['contenu'] != null) {
      body = dataMap['contenu'].toString();
    }

    return AppNotification(
      id: json['id'].toString(),
      type: json['type'] ?? 'default',
      title: dataMap['title'] ?? 'Notification',
      body: body,
      sender: sender,
      isRead: json['read_at'] != null,
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
