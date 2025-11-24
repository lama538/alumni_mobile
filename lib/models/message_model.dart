class AppMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String contenu;
  bool isRead;
  final String senderName;
  final String receiverName;
  final DateTime createdAt;
  final String? senderEmail;
  final String? senderPhoto;
  final String? senderRole;
  final String? receiverEmail;   // ✅ Ajouté
  final String? receiverPhoto;   // ✅ Ajouté
  final String? receiverRole;    // ✅ Ajouté
  final String? media;
  final String? mediaType;

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
    this.senderRole,
    this.receiverEmail,   // ✅ Ajouté
    this.receiverPhoto,   // ✅ Ajouté
    this.receiverRole,    // ✅ Ajouté
    this.media,
    this.mediaType,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) {
    // Photo de l'expéditeur
    String? senderPhoto;
    if (json['sender'] != null && json['sender']['photo'] != null) {
      final photoPath = json['sender']['photo'].toString();
      senderPhoto = photoPath.startsWith('http')
          ? photoPath
          : 'http://10.0.2.2:8000/storage/$photoPath';
    }

    // Photo du destinataire ✅
    String? receiverPhoto;
    if (json['receiver'] != null && json['receiver']['photo'] != null) {
      final photoPath = json['receiver']['photo'].toString();
      receiverPhoto = photoPath.startsWith('http')
          ? photoPath
          : 'http://10.0.2.2:8000/storage/$photoPath';
    }

    // URL du média
    String? mediaUrl;
    if (json['media'] != null) {
      final mediaPath = json['media'].toString();
      mediaUrl = mediaPath.startsWith('http')
          ? mediaPath
          : 'http://10.0.2.2:8000/storage/$mediaPath';
    }

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
      senderPhoto: senderPhoto,
      senderRole: json['sender']?['role'] ?? 'alumni',
      receiverEmail: json['receiver']?['email'],     // ✅ Ajouté
      receiverPhoto: receiverPhoto,                  // ✅ Ajouté
      receiverRole: json['receiver']?['role'] ?? 'alumni', // ✅ Ajouté
      media: mediaUrl,
      mediaType: json['media_type'],
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
      'sender_role': senderRole,
      'receiver_email': receiverEmail,    // ✅ Ajouté
      'receiver_photo': receiverPhoto,    // ✅ Ajouté
      'receiver_role': receiverRole,      // ✅ Ajouté
      'media': media,
      'media_type': mediaType,
      'created_at': createdAt.toIso8601String(),
    };
  }
}