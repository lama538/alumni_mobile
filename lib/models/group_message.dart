class GroupMessage {
  final int id;
  final int groupeId;
  final int userId;
  final String message ;
  final DateTime createdAt;
  final String senderName;

  GroupMessage({
    required this.id,
    required this.groupeId,
    required this.userId,
    required this.message,
    required this.createdAt,
    required this.senderName,
  });

  factory GroupMessage.fromJson(Map<String, dynamic> json) {
    return GroupMessage(
      id: json['id'],
      groupeId: json['groupe_id'],
      userId: json['user_id'],
      message: json['message'],
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['user']['name'] ?? 'Anonyme',
    );
  }
}
