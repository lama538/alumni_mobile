import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? profil;
  bool isLoading = true;
  bool isEditing = false;

  final TextEditingController parcoursController = TextEditingController();
  final TextEditingController experiencesController = TextEditingController();
  final TextEditingController competencesController = TextEditingController();
  final TextEditingController realisationsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfil();
  }

  Future<void> fetchProfil() async {
    setState(() => isLoading = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/profil'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profilData = data['profil'];
        setState(() {
          profil = profilData;
          if (profil != null) {
            parcoursController.text = profil!['parcours_academique'] ?? '';
            experiencesController.text =
                profil!['experiences_professionnelles'] ?? '';
            competencesController.text = profil!['competences'] ?? '';
            realisationsController.text = profil!['realisations'] ?? '';
          }
        });
      } else {
        profil = null;
      }
    } catch (e) {
      debugPrint("Erreur profil: $e");
      profil = null;
    } finally {
      setState(() => isLoading = false);
    }


  }

  Future<void> createOrUpdateProfil({bool update = false}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final url = Uri.parse('http://10.0.2.2:8000/api/profil');
    final headers = {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };

    final body = {
      'parcours_academique': parcoursController.text,
      'experiences_professionnelles': experiencesController.text,
      'competences': competencesController.text,
      'realisations': realisationsController.text,
    };

    final response =
    update ? await http.put(url, headers: headers, body: body) : await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(update
              ? 'Profil mis à jour avec succès !'
              : 'Profil créé avec succès !'),
          backgroundColor: Colors.green,
        ),
      );
      await fetchProfil();
      setState(() => isEditing = false);
    }


  }

  Future<void> deleteProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/profil'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        profil = null;
        parcoursController.clear();
        experiencesController.clear();
        competencesController.clear();
        realisationsController.clear();
        isEditing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil supprimé !'),
          backgroundColor: Colors.red,
        ),
      );
    }


  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        backgroundColor: Colors.deepPurple,
        actions: [
          if (profil != null && !isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => isEditing = true),
            ),
        ],
      ),
      body: profil == null
          ? _buildForm(isNew: true)
          : isEditing
          ? _buildForm(isNew: false)
          : _buildProfilView(),
    );


  }

  Widget _buildProfilView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _infoCard(Icons.school, "Formation", profil!['parcours_academique']),
          _infoCard(
              Icons.work, "Expériences", profil!['experiences_professionnelles']),
          _infoCard(Icons.psychology, "Compétences", profil!['competences']),
          _infoCard(Icons.emoji_events, "Réalisations", profil!['realisations']),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: deleteProfil,
            icon: const Icon(Icons.delete),
            label: const Text("Supprimer le profil"),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isNew}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            isNew ? "Créer votre profil" : "Modifier votre profil",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildFormFields(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () =>
                      createOrUpdateProfil(update: !isNew),
                  icon: const Icon(Icons.check),
                  label: Text(isNew ? "Créer" : "Enregistrer"),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple),
                ),
              ),
              const SizedBox(width: 12),
              if (!isNew)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() => isEditing = false),
                    child: const Text("Annuler"),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _textField(parcoursController, "Formation académique", Icons.school),
        const SizedBox(height: 12),
        _textField(experiencesController, "Expériences professionnelles", Icons.work),
        const SizedBox(height: 12),
        _textField(competencesController, "Compétences", Icons.psychology),
        const SizedBox(height: 12),
        _textField(realisationsController, "Réalisations", Icons.emoji_events),
      ],
    );
  }

  Widget _textField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.deepPurple),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, String? content) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle:
        Text(content?.isNotEmpty == true ? content! : "Non renseigné"),
      ),
    );
  }
}