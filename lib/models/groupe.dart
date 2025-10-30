import '../models/ user.dart';
class Groupe {

  final int id;
  final String nom;
  final String? description;
  final int creatorId;
  final List<User> membres;

  Groupe({
    required this.id,
    required this.nom,
    this.description,
    required this.creatorId,
    required this.membres,
  });

  factory Groupe.fromJson(Map<String, dynamic> json) {
    return Groupe(
      id: json['id'],
      nom: json['nom'],
      description: json['description'],
      creatorId: json['creator_id'],
      membres: (json['membres'] as List)
          .map((m) => User.fromJson(m))
          .toList(),
    );
  }
}
