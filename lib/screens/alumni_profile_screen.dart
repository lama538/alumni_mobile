import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AlumniProfileScreen extends StatefulWidget {
  const AlumniProfileScreen({super.key});

  @override
  State<AlumniProfileScreen> createState() => _AlumniProfileScreenState();
}

class _AlumniProfileScreenState extends State<AlumniProfileScreen> {
  final TextEditingController parcoursController = TextEditingController();
  final TextEditingController experienceController = TextEditingController();
  final TextEditingController competencesController = TextEditingController();
  final TextEditingController realisationsController = TextEditingController();

  bool isLoading = false;
  String token = '';
  String alumniName = '';

  @override
  void initState() {
    super.initState();
    loadTokenAndName();
  }

  // Récupère le token et le nom de l'alumni après connexion
  void loadTokenAndName() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    alumniName = prefs.getString('name') ?? '';

    // Affiche le message de bienvenue
    if (alumniName.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Bienvenue $alumniName !"),
            backgroundColor: Colors.green,
          ),
        );
      });
    }

    fetchProfile();
  }

  // Récupérer le profil depuis l'API
  void fetchProfile() async {
    if (token.isEmpty) return;
    setState(() => isLoading = true);
    try {
      final response = await ApiService.getAlumniProfile(token);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)['profil'];
        parcoursController.text = data['parcours_academique'] ?? '';
        experienceController.text = data['experiences_professionnelles'] ?? '';
        competencesController.text = data['competences'] ?? '';
        realisationsController.text = data['realisations'] ?? '';
      } else if (response.statusCode == 404) {
        // Aucun profil, créer un profil vide automatiquement
        await ApiService.createProfile(token, {
          "parcours_academique": "",
          "experiences_professionnelles": "",
          "competences": "",
          "realisations": "",
        });
        print("Profil créé automatiquement.");
      } else {
        print("Erreur fetch profile: ${response.body}");
      }
    } catch (e) {
      print("Erreur fetch profile: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Enregistrer / mettre à jour le profil
  void saveProfile() async {
    if (token.isEmpty) return;
    setState(() => isLoading = true);

    final data = {
      "parcours_academique": parcoursController.text,
      "experiences_professionnelles": experienceController.text,
      "competences": competencesController.text,
      "realisations": realisationsController.text,
    };

    try {
      final response = await ApiService.updateProfile(token, data);
      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour avec succès")),
        );
      } else {
        print("Erreur save profile: ${response.body}");
      }
    } catch (e) {
      print("Erreur save profile: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  // Supprimer le profil
  void deleteProfile() async {
    if (token.isEmpty) return;
    setState(() => isLoading = true);

    try {
      final response = await ApiService.deleteProfile(token);
      if (response.statusCode == 200) {
        parcoursController.clear();
        experienceController.clear();
        competencesController.clear();
        realisationsController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil supprimé")),
        );
      } else {
        print("Erreur delete profile: ${response.body}");
      }
    } catch (e) {
      print("Erreur delete profile: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Profil de $alumniName")),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildTextField("Parcours académique", parcoursController),
                  _buildTextField("Expériences professionnelles", experienceController),
                  _buildTextField("Compétences", competencesController),
                  _buildTextField("Réalisations", realisationsController),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: saveProfile,
                    child: const Text("Enregistrer / Mettre à jour"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: deleteProfile,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text("Supprimer le profil"),
                  ),
                ],
              ),
            ),
          ),
          if (isLoading)
            Container(
              color: Colors.black45,
              child: const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        maxLines: null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
