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
    // ✅ Le backend renvoie déjà les données au premier niveau via le map()
    // Pas besoin de chercher dans 'data'

    String title = 'Notification';
    String body = '';
    String? sender;

    // ✅ Vérifier si les données sont au premier niveau (depuis le map() du backend)
    if (json.containsKey('title') && json['title'] != null) {
      title = json['title'].toString();
    }

    if (json.containsKey('body') && json['body'] != null) {
      body = json['body'].toString();
    }

    if (json.containsKey('sender') && json['sender'] != null) {
      sender = json['sender'].toString();
    }

    // ✅ Fallback : si 'data' existe en tant que Map (cas où Laravel n'a pas mappé)
    if (json.containsKey('data') && json['data'] != null) {
      Map<String, dynamic> dataMap = {};

      if (json['data'] is String) {
        try {
          dataMap = jsonDecode(json['data']);
        } catch (_) {
          dataMap = {};
        }
      } else if (json['data'] is Map) {
        dataMap = Map<String, dynamic>.from(json['data']);
      }

      // Si title/body/sender ne sont pas au premier niveau, les chercher dans 'data'
      if (title == 'Notification' && dataMap['title'] != null) {
        title = dataMap['title'].toString();
      }

      if (body.isEmpty) {
        if (dataMap['body'] != null) {
          body = dataMap['body'].toString();
        } else if (dataMap['message'] != null) {
          body = dataMap['message'].toString();
        } else if (dataMap['contenu'] != null) {
          body = dataMap['contenu'].toString();
        }
      }

      if (sender == null) {
        // Gérer le cas où sender est un objet
        if (dataMap['sender'] is Map) {
          sender = dataMap['sender']['name']?.toString();
        } else if (dataMap['sender'] != null) {
          sender = dataMap['sender'].toString();
        }
      }
    }

    // ✅ Valeurs par défaut si toujours vides
    if (body.isEmpty) {
      body = 'Vous avez reçu une nouvelle notification';
    }
    if (sender == null || sender.isEmpty) {
      sender = 'Quelqu\'un';
    }

    return AppNotification(
      id: json['id'].toString(),
      type: json['type']?.toString() ?? 'default',
      title: title,
      body: body,
      sender: sender,
      isRead: json['is_read'] == true || json['read_at'] != null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'sender': sender,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}