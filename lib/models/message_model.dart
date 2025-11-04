// lib/models/message_model.dart

class AppMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String contenu;
  bool isRead;
  final String senderName;
  final String receiverName;
  final DateTime createdAt;
  final String? senderEmail; // optionnel
  final String? senderPhoto; // optionnel pour avatar
  final String? media; // chemin image/vidéo
  final String? mediaType; // "image" ou "video"

  AppMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.contenu,
    required this.isRead,
    required this.senderName,
    required this.receiverName,
    required this.createdAt,
    this.senderEmail,
    this.senderPhoto,
    this.media,
    this.mediaType,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) {
    // gestion sécurisée de la photo
    String? photo;
    if (json['sender'] != null && json['sender']['photo'] != null) {
      final photoPath = json['sender']['photo'].toString();
      photo = photoPath.startsWith('http')
          ? photoPath
          : 'http://10.0.2.2:8000/storage/$photoPath';
    }

    // gestion sécurisée du media
    String? mediaUrl;
    if (json['media'] != null) {
      final mediaPath = json['media'].toString();
      mediaUrl = mediaPath.startsWith('http')
          ? mediaPath
          : 'http://10.0.2.2:8000/storage/$mediaPath';
    }

    // date de création
    DateTime createdAt;
    try {
      createdAt = DateTime.parse(json['created_at']);
    } catch (_) {
      createdAt = DateTime.now();
    }

    return AppMessage(
      id: json['id'] ?? 0,
      senderId: json['sender_id'] ?? 0,
      receiverId: json['receiver_id'] ?? 0,
      contenu: json['contenu'] ?? '',
      isRead: json['is_read'] ?? false,
      senderName: json['sender']?['name'] ?? '',
      receiverName: json['receiver']?['name'] ?? '',
      senderEmail: json['sender']?['email'],
      senderPhoto: photo,
      media: mediaUrl,
      mediaType: json['media_type'], // <-- ajouté
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'contenu': contenu,
      'is_read': isRead,
      'sender_name': senderName,
      'receiver_name': receiverName,
      'sender_email': senderEmail,
      'sender_photo': senderPhoto,
      'media': media,
      'media_type': mediaType, // <-- ajouté
      'created_at': createdAt.toIso8601String(),
    };
  }
}
