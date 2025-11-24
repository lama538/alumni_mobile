class GroupMessage {
  final int id;
  final int groupeId;
  final int userId;
  final String message;
  final DateTime createdAt;
  final String senderName;
  final String? media;      // ✅ Lien complet du média
  final String? mediaType;  // "image" ou "video"

  GroupMessage({
    required this.id,
    required this.groupeId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.senderName,
    this.media,
    this.mediaType,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    // 🔹 Construction sécurisée de l'URL du média
    String? mediaUrl;
    if (json['media'] != null) {
      final mediaPath = json['media'].toString();
      mediaUrl = mediaPath.startsWith('http')
          ? mediaPath
          : 'http://10.0.2.2:8000/storage/$mediaPath'; // adapte selon ton API
    }

    return GroupMessage(
      id: json['id'] ?? 0,
      groupeId: json['groupe_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      message: json['message'] ?? '',
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
      senderName: json['user']?['name'] ?? 'Anonyme',
      media: mediaUrl, // ✅ URL complète et sûre
      mediaType: json['media_type'],
    );
  }
}
