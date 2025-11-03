import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  Map<String, dynamic>? profil;
  Map<String, dynamic>? user;
  bool isLoading = true;
  bool isEditing = false;
  bool isSubmitting = false;

  File? _imageFile;

  final TextEditingController bioController = TextEditingController();
  final TextEditingController parcoursController = TextEditingController();
  final TextEditingController experiencesController = TextEditingController();
  final TextEditingController competencesController = TextEditingController();
  final TextEditingController realisationsController = TextEditingController();

  int abonnesCount = 0;
  int abonnementsCount = 0;

  final String baseUrl = "http://10.0.2.2:8000/storage/";

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
        Uri.parse('http://10.0.2.2:8000/api/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          profil = data['profil'];
          user = data['user'];

          abonnesCount = data['abonnes_count'] ?? 0;
          abonnementsCount = data['abonnements_count'] ?? 0;

          bioController.text = profil?['bio'] ?? '';
          parcoursController.text = profil?['parcours_academique'] ?? '';
          experiencesController.text =
              profil?['experiences_professionnelles'] ?? '';
          competencesController.text = profil?['competences'] ?? '';
          realisationsController.text = profil?['realisations'] ?? '';

          _imageFile = null;
        });
      } else {
        setState(() {
          profil = null;
          user = null;
        });
      }
    } catch (e) {
      debugPrint("Erreur profil: $e");
      setState(() {
        profil = null;
        user = null;
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> createOrUpdateProfil() async {
    setState(() => isSubmitting = true);
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Utilisateur non authentifié"),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSubmitting = false);
        return;
      }

      bool hasProfil = profil != null;

      final url = Uri.parse('http://10.0.2.2:8000/api/profile');

      var request = http.MultipartRequest('POST', url);
      if (hasProfil) request.fields['_method'] = 'PUT';

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['bio'] = bioController.text;
      request.fields['parcours_academique'] = parcoursController.text;
      request.fields['experiences_professionnelles'] =
          experiencesController.text;
      request.fields['competences'] = competencesController.text;
      request.fields['realisations'] = realisationsController.text;

      if (_imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _imageFile!.path),
        );
      }

      var response = await request.send();
      var body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              hasProfil
                  ? 'Profil mis à jour avec succès'
                  : 'Profil créé avec succès',
            ),
            backgroundColor: const Color(0xFF4CAF50),
          ),
        );

        await fetchProfil();
        setState(() => isEditing = false);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la mise à jour : $body"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("Erreur lors de la création du profil : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Erreur de connexion au serveur"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  Future<void> deleteProfil() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Voulez-vous vraiment supprimer votre profil ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Supprimer"),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('http://10.0.2.2:8000/api/profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      setState(() {
        profil = null;
        user = null;
        _imageFile = null;
        bioController.clear();
        parcoursController.clear();
        experiencesController.clear();
        competencesController.clear();
        realisationsController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profil supprimé avec succès"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  ImageProvider _getAvatar() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (profil != null &&
        profil!['photo'] != null &&
        profil!['photo'].toString().isNotEmpty) {
      String url = profil!['photo'].toString();
      if (!url.startsWith('http')) url = '$baseUrl$url';
      return NetworkImage(url);
    }
    if (user != null &&
        user!['photo'] != null &&
        user!['photo'].toString().isNotEmpty) {
      String url = user!['photo'].toString();
      if (!url.startsWith('http')) url = '$baseUrl$url';
      return NetworkImage(url);
    }
    return const AssetImage('assets/images/default_avatar.png');
  }

  Future<void> _showListeUtilisateurs(String type) async {
    setState(() => isLoading = true);
    List<dynamic> liste = [];
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      if (token == null) return;

      // Déterminer l'URL selon le type
      String url = '';
      int userId = user?['id'] ?? 0;
      if (type == "Abonnés") {
        url = 'http://10.0.2.2:8000/api/profil/abonnes/$userId';
      } else if (type == "Abonnements") {
        url = 'http://10.0.2.2:8000/api/profil/abonnements/$userId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        liste = jsonDecode(response.body);
      } else {
        debugPrint("Erreur fetch $type: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur fetch $type: $e");
    } finally {
      setState(() => isLoading = false);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(type),
        content: SizedBox(
          width: double.maxFinite,
          child: liste.isEmpty
              ? const Text("Aucun utilisateur à afficher")
              : ListView.builder(
            shrinkWrap: true,
            itemCount: liste.length,
            itemBuilder: (context, index) {
              final utilisateur = liste[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: utilisateur['photo'] != null
                      ? NetworkImage(utilisateur['photo'])
                      : const AssetImage(
                      'assets/images/default_avatar.png') as ImageProvider,
                ),
                title: Text(utilisateur['name'] ?? ''),
                subtitle: Text(utilisateur['email'] ?? ''),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Fermer"),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mon Profil",
          style: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
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
      child: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2196F3),
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _getAvatar(),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => isEditing = true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  user?['email'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _showListeUtilisateurs("Abonnements"),
                      child: _buildStatItem("Abonnements", abonnementsCount),
                    ),
                    Container(
                      height: 40,
                      width: 1,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    GestureDetector(
                      onTap: () => _showListeUtilisateurs("Abonnés"),
                      child: _buildStatItem("Abonnés", abonnesCount),
                    ),
                  ],
                ),
                if (profil?['bio'] != null && profil!['bio'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Text(
                      profil!['bio'],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[700],
                        height: 1.4,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (profil?['parcours_academique'] != null &&
              profil!['parcours_academique'].toString().isNotEmpty)
            _buildInfoSection(
              Icons.school_outlined,
              "Formation académique",
              profil!['parcours_academique'],
            ),
          if (profil?['experiences_professionnelles'] != null &&
              profil!['experiences_professionnelles'].toString().isNotEmpty)
            _buildInfoSection(
              Icons.work_outline,
              "Expériences professionnelles",
              profil!['experiences_professionnelles'],
            ),
          if (profil?['competences'] != null &&
              profil!['competences'].toString().isNotEmpty)
            _buildInfoSection(
              Icons.emoji_objects_outlined,
              "Compétences",
              profil!['competences'],
            ),
          if (profil?['realisations'] != null &&
              profil!['realisations'].toString().isNotEmpty)
            _buildInfoSection(
              Icons.emoji_events_outlined,
              "Réalisations",
              profil!['realisations'],
            ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: deleteProfil,
              icon: const Icon(Icons.delete_outline, size: 20),
              label: const Text("Supprimer le profil"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      children: [
        Text(
          "$count",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoSection(IconData icon, String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2196F3).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF2196F3),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm({required bool isNew}) {
    return AbsorbPointer(
      absorbing: isSubmitting,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2196F3),
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _getAvatar(),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3),
                              shape: BoxShape.circle,
                              border:
                              Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Toucher pour changer la photo",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isNew ? "Créer votre profil" : "Modifier votre profil",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 20),
            _textField(bioController, "Bio", Icons.info_outline),
            _textField(
                parcoursController, "Formation académique", Icons.school_outlined),
            _textField(experiencesController, "Expériences professionnelles",
                Icons.work_outline),
            _textField(competencesController, "Compétences",
                Icons.emoji_objects_outlined),
            _textField(realisationsController, "Réalisations",
                Icons.emoji_events_outlined),
            const SizedBox(height: 24),
            if (isSubmitting)
              const CircularProgressIndicator(color: Color(0xFF2196F3))
            else
              Column(
                children: [
                  ElevatedButton(
                    onPressed: createOrUpdateProfil,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      isNew ? "Créer mon profil" : "Enregistrer les modifications",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (!isNew) ...[
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed: () => setState(() => isEditing = false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF2196F3),
                        side: const BorderSide(color: Color(0xFF2196F3)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Annuler",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _textField(
      TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: 3,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          prefixIcon: Icon(icon, color: const Color(0xFF2196F3), size: 22),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3), width: 2),
          ),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
