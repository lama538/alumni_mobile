class AppMessage {
  final int id;
  final int senderId;
  final int receiverId;
  final String contenu;
  bool isRead;
  final String senderName;
  final String receiverName;
  final DateTime createdAt;
  final String senderEmail;

  AppMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.contenu,
    required this.isRead,
    required this.senderName,
    required this.receiverName,
    required this.createdAt,
    required this.senderEmail,
  });

  factory AppMessage.fromJson(Map<String, dynamic> json) {
    return AppMessage(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      contenu: json['contenu'] ?? '',
      isRead: json['is_read'] ?? false,
      senderName: json['sender']?['name'] ?? '',
      receiverName: json['receiver']?['name'] ?? '',
      senderEmail: json['sender']?['email'] ?? '',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
