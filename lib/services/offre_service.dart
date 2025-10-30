import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/offre_model.dart';
import 'api_service.dart';

class OffreService {
  // 🔹 Récupérer toutes les offres
  static Future<List<Offre>> getAll(String token) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((j) => Offre.fromJson(j)).toList();
    } else {
      throw Exception('Erreur get offres: ${res.body}');
    }
  }

  // 🔹 Récupérer une offre
  static Future<Offre> getOne(String token, int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres/$id');
    final res = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode == 200) {
      return Offre.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Erreur get offre: ${res.body}');
    }
  }

  // 🔹 Créer une offre
  static Future<Offre> create(String token, Offre offre) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(offre.toJson()),
    );

    if (res.statusCode == 200 || res.statusCode == 201) {
      return Offre.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Erreur create offre: ${res.body}');
    }
  }

  // 🔹 Mettre à jour une offre
  static Future<Offre> update(String token, int id, Offre offre) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres/$id');
    final res = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(offre.toJson()),
    );

    if (res.statusCode == 200) {
      return Offre.fromJson(jsonDecode(res.body));
    } else {
      throw Exception('Erreur update offre: ${res.body}');
    }
  }

  // 🔹 Supprimer une offre
  static Future<void> delete(String token, int id) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres/$id');
    final res = await http.delete(url, headers: {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('Erreur delete offre: ${res.body}');
    }
  }

  // 🔹 Postuler avec message simple
  static Future<void> apply(
      String token,
      int offreId,
      int studentId,
      String? message,
      ) async {
    final url = Uri.parse('${ApiService.baseUrl}/offres/$offreId/apply');
    final res = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'student_id': studentId, 'message': message ?? ''}),
    );

    if (res.statusCode != 200 && res.statusCode != 201) {
      final resp = jsonDecode(res.body);
      throw Exception(resp['message'] ?? 'Erreur apply: ${res.body}');
    }
  }

  // 🔹 Postuler avec formulaire complet (CV inclus)
  static Future<void> applyWithForm({
    required String token,
    required int offreId,
    required int studentId,
    required String prenom,
    required String nom,
    required String email,
    required String telephone,
    required String cvPath,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/offres/$offreId/apply');
    final request = http.MultipartRequest('POST', uri);

    request.headers['Authorization'] = 'Bearer $token';
    request.fields['student_id'] = studentId.toString();
    request.fields['prenom'] = prenom;
    request.fields['nom'] = nom;
    request.fields['email'] = email;
    request.fields['telephone'] = telephone;
    request.files.add(await http.MultipartFile.fromPath('cv', cvPath));

    final response = await request.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode != 200 && response.statusCode != 201) {
      // ✅ Tente extraire le message précis du backend
      try {
        final jsonResp = jsonDecode(respStr);
        throw Exception(jsonResp['message'] ?? 'Erreur applyWithForm');
      } catch (_) {
        throw Exception('Erreur applyWithForm: $respStr');
      }
    }
  }

  // 🔹 Vérifie si l'utilisateur a déjà postulé
  static Future<bool> hasApplied(
      String token, int offreId, int studentId) async {
    final response = await http.get(
      Uri.parse('${ApiService.baseUrl}/offres/$offreId/candidatures/$studentId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['hasApplied'] ?? false;
    }
    return false;
  }
}
