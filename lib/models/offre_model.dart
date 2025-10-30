// lib/models/offre_model.dart
class Offre {
  final int id;
  final int? userId;
  final String titre;
  final String description;
  final String type; // 'emploi' or 'stage'
  final DateTime? dateExpiration;
  final String? userName; // optionnel : nom de l'auteur

  Offre({
    required this.id,
    this.userId,
    required this.titre,
    required this.description,
    required this.type,
    this.dateExpiration,
    this.userName,
  });

  factory Offre.fromJson(Map<String, dynamic> json) {
    return Offre(
      id: json['id'],
      userId: json['user_id'] != null ? json['user_id'] as int : null,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      type: json['type'] ?? '',
      dateExpiration: json['date_expiration'] != null
          ? DateTime.parse(json['date_expiration'])
          : null,
      userName: json['user']?['name'] ?? json['user_name'] ?? null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'titre': titre,
      'description': description,
      'type': type,
      'date_expiration': dateExpiration?.toIso8601String(),
    };
  }
}
