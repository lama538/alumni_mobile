import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AdminActualitesScreen extends StatefulWidget {
  const AdminActualitesScreen({super.key});

  @override
  State<AdminActualitesScreen> createState() => _AdminActualitesScreenState();
}

class _AdminActualitesScreenState extends State<AdminActualitesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  File? _selectedImage;
  File? _selectedVideo;
  String? _token;
  int? _userId;
  int? _editingId;
  List actualites = [];
  bool _loading = false;

  final String baseUrl = "http://10.0.2.2:8000";

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getInt('user_id');

    if (_token != null) {
      _fetchActualites();
    } else {
      debugPrint("❌ Aucun token trouvé");
    }
  }

  Future<void> _fetchActualites() async {
    setState(() => _loading = true);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/actualites'),
        headers: {
          "Accept": "application/json",
          "Authorization": "Bearer $_token",
        },
      );

      if (response.statusCode == 200) {
        final List all = jsonDecode(response.body);
        setState(() {
          actualites = all.where((a) => a['auteur']?['id'] == _userId).toList();
        });
      } else {
        debugPrint("Erreur API: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Erreur fetch: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedVideo = File(picked.path));
  }

  Future<void> _createOrUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    if (_token == null) return;

    setState(() => _loading = true);

    final uri = _editingId == null
        ? Uri.parse('$baseUrl/api/actualites')
        : Uri.parse('$baseUrl/api/actualites/$_editingId');

    final request = http.MultipartRequest(_editingId == null ? 'POST' : 'POST', uri);
    if (_editingId != null) request.fields['_method'] = 'PUT';

    request.headers['Authorization'] = 'Bearer $_token';
    request.headers['Accept'] = 'application/json';
    request.fields['titre'] = _titreController.text;
    request.fields['contenu'] = _contenuController.text;

    if (_selectedImage != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _selectedImage!.path));
    }

    if (_selectedVideo != null) {
      request.files.add(await http.MultipartFile.fromPath('video', _selectedVideo!.path));
    }

    try {
      final response = await request.send();
      final respStr = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingId == null
                ? "Actualité publiée avec succès"
                : "Actualité mise à jour avec succès"),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        _resetForm();
        _fetchActualites();
      } else {
        debugPrint("❌ Erreur API : ${response.statusCode}");
        debugPrint(respStr);
      }
    } catch (e) {
      debugPrint("❌ Erreur envoi : $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  void _resetForm() {
    _titreController.clear();
    _contenuController.clear();
    _selectedImage = null;
    _selectedVideo = null;
    _editingId = null;
    setState(() {});
  }

  void _edit(Map act) {
    _titreController.text = act['titre'];
    _contenuController.text = act['contenu'];
    _editingId = act['id'];
    _selectedImage = null;
    _selectedVideo = null;
    setState(() {});
  }

  Future<void> _delete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cette actualité ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (_token == null) return;
    final response = await http.delete(
      Uri.parse('$baseUrl/api/actualites/$id'),
      headers: {
        "Authorization": "Bearer $_token",
        "Accept": "application/json",
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Actualité supprimée avec succès"),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _fetchActualites();
    } else {
      debugPrint("❌ Erreur suppression : ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Mes Publications",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
          strokeWidth: 3,
        ),
      )
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Formulaire de création/édition
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _editingId == null
                          ? "Nouvelle Post"
                          : "Modifier le Post",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titreController,
                      decoration: InputDecoration(
                        labelText: "Titre",
                        labelStyle: TextStyle(color: Colors.grey[600]),
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      validator: (v) => v!.isEmpty ? "Titre requis" : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contenuController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        labelText: "Contenu",
                        labelStyle: TextStyle(color: Colors.grey[600]),
                        alignLabelWithHint: true,
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
                          borderSide: const BorderSide(
                            color: Color(0xFF2196F3),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(0xFFFAFAFA),
                      ),
                      validator: (v) => v!.isEmpty ? "Contenu requis" : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: _selectedImage != null
                                  ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                ),
                              )
                                  : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.add_photo_alternate_outlined,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Ajouter une image",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: _pickVideo,
                            child: Container(
                              height: 120,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFAFAFA),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedVideo != null
                                        ? Icons.videocam
                                        : Icons.videocam_outlined,
                                    size: 40,
                                    color: _selectedVideo != null
                                        ? const Color(0xFFE53935)
                                        : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _selectedVideo != null
                                        ? "Vidéo sélectionnée"
                                        : "Ajouter une vidéo",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        if (_editingId != null)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _resetForm,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              child: const Text(
                                "Annuler",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF666666),
                                ),
                              ),
                            ),
                          ),
                        if (_editingId != null) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _createOrUpdate,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _editingId == null ? "Publier" : "Mettre à jour",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Liste des actualités
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                "Mes publications (${actualites.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (actualites.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 80,
                        color: Colors.grey[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Aucune publication",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: actualites.length,
                itemBuilder: (context, index) {
                  final act = actualites[index];
                  final date = act['created_at'] != null
                      ? DateFormat('dd MMM yyyy').format(
                      DateTime.parse(act['created_at']))
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Aperçu média
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: act['image'] != null
                                ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                act['image'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stack) =>
                                    Icon(Icons.image_outlined,
                                        color: Colors.grey[400]),
                              ),
                            )
                                : act['video'] != null
                                ? Icon(Icons.videocam,
                                size: 40, color: Colors.grey[400])
                                : Icon(Icons.article_outlined,
                                size: 40, color: Colors.grey[400]),
                          ),
                          const SizedBox(width: 12),

                          // Contenu
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  act['titre'],
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1A1A1A),
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  date,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.favorite,
                                              size: 14, color: Color(0xFF2196F3)),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${act['likes_count'] ?? 0}",
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2196F3),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.comment,
                                              size: 14, color: Colors.grey[600]),
                                          const SizedBox(width: 4),
                                          Text(
                                            "${act['comments_count'] ?? 0}",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Column(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    color: Color(0xFF2196F3), size: 20),
                                onPressed: () => _edit(act),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                              const SizedBox(height: 8),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    color: Color(0xFFE53935), size: 20),
                                onPressed: () => _delete(act['id']),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}