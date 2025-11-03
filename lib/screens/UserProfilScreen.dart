import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class UserProfilScreen extends StatefulWidget {
  final int userId;

  const UserProfilScreen({super.key, required this.userId});

  @override
  State<UserProfilScreen> createState() => _UserProfilScreenState();
}

class _UserProfilScreenState extends State<UserProfilScreen> {
  Map<String, dynamic>? profilData;
  bool isLoading = true;
  bool isOwner = false;
  bool isFollowing = false;

  List<dynamic> abonnesList = [];
  List<dynamic> abonnementsList = [];

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    setState(() => isLoading = true);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final currentUserId = prefs.getInt('user_id');

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/users/${widget.userId}/profil'),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          profilData = data;
          isOwner = widget.userId == currentUserId;
          isFollowing = data['is_following'] ?? false;

          profilData!['abonnes_count'] = data['abonnes_count'] ?? 0;
          profilData!['abonnements_count'] = data['abonnements_count'] ?? 0;
        });
      } else {
        debugPrint('Erreur chargement profil: ${response.statusCode} ${response.body}');
        setState(() => profilData = null);
      }
    } catch (e) {
      debugPrint("Erreur réseau: $e");
      setState(() => profilData = null);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/profil/follow/${widget.userId}'),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          isFollowing = data['is_following'] ?? data['isFollowing'] ?? false;
          profilData!['abonnes_count'] = data['abonnes_count'] ?? profilData!['abonnes_count'];
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isFollowing ? 'Abonné avec succès' : 'Désabonné avec succès'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        debugPrint("Erreur suivi: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Erreur suivi (${response.statusCode})"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur réseau suivi: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur réseau suivi"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:8000/api/profil'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profil supprimé avec succès"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } else {
        debugPrint("Erreur suppression: ${response.statusCode} ${response.body}");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Erreur lors de la suppression"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Erreur suppression: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Erreur réseau"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadListe(String type) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    Uri uri;
    if (type.toLowerCase() == 'abonnes') {
      uri = Uri.parse('http://10.0.2.2:8000/api/profil/abonnes/${widget.userId}');
    } else {
      uri = Uri.parse('http://10.0.2.2:8000/api/profil/abonnements/${widget.userId}');
    }

    try {
      final response = await http.get(uri, headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
      });

      if (response.statusCode == 200) {
        setState(() {
          if (type.toLowerCase() == 'abonnes') {
            abonnesList = jsonDecode(response.body) as List<dynamic>;
          } else {
            abonnementsList = jsonDecode(response.body) as List<dynamic>;
          }
        });
      } else {
        debugPrint("Erreur récupération $type: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Erreur réseau $type: $e");
    }
  }

  Future<void> _showListeUtilisateurs(String type) async {
    await _loadListe(type); // Charger d'abord la liste
    if (!mounted) return;

    List<dynamic> liste = type.toLowerCase() == 'abonnes' ? abonnesList : abonnementsList;

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
              final item = liste[index];
              final name = item['name'] ?? 'Utilisateur';
              final email = item['email'] ?? '';
              final photo = item['photo'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: photo.isNotEmpty
                      ? NetworkImage(photo)
                      : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                ),
                title: Text(name),
                subtitle: email.isNotEmpty ? Text(email) : null,
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

  Widget _buildStatCard(String label, int count, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 12),
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String title, String content, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            content,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2196F3)),
        ),
      );
    }

    if (profilData == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black87),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Profil non trouvé",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final user = profilData!['user'] ?? {};
    final profil = profilData!['profil'] ?? {};
    final abonnesCount = profilData!['abonnes_count'] ?? 0;
    final abonnementsCount = profilData!['abonnements_count'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Avatar et nom
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.white,
                  child: CircleAvatar(
                    radius: 65,
                    backgroundImage: (user['photo'] != null && user['photo'].toString().isNotEmpty)
                        ? NetworkImage(user['photo'])
                        : const AssetImage('assets/images/default_avatar.png') as ImageProvider,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                (user['name'] ?? 'Utilisateur').toString(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                (user['email'] ?? '').toString(),
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Statistiques abonnés / abonnements
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () => _showListeUtilisateurs("Abonnes"),
                      child: _buildStatCard(
                        "Abonnés",
                        abonnesCount,
                        Icons.people,
                        const Color(0xFF2196F3),
                      ),
                    ),
                    Container(
                      height: 50,
                      width: 1,
                      color: Colors.grey[300],
                    ),
                    GestureDetector(
                      onTap: () => _showListeUtilisateurs("Abonnements"),
                      child: _buildStatCard(
                        "Abonnements",
                        abonnementsCount,
                        Icons.person_add,
                        const Color(0xFF4CAF50),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Boutons suivre / modifier / supprimer
              if (!isOwner)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ElevatedButton(
                    onPressed: _toggleFollow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isFollowing ? Colors.grey[300] : const Color(0xFF2196F3),
                      foregroundColor: isFollowing ? Colors.black87 : Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isFollowing ? 'Se désabonner' : 'Suivre',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),

              if (isOwner)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2196F3),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 2,
                        ),
                        onPressed: () {
                          Navigator.pushNamed(context, '/profil');
                        },
                        icon: const Icon(Icons.edit, size: 20),
                        label: const Text(
                          "Modifier",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              title: const Text("Confirmation"),
                              content: const Text(
                                "Voulez-vous vraiment supprimer votre profil ?",
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text("Annuler"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                  child: const Text("Supprimer"),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            await _deleteProfil();
                          }
                        },
                        icon: const Icon(Icons.delete_outline, size: 20),
                        label: const Text(
                          "Supprimer",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Infos profil
              if (profil['bio'] != null && profil['bio'].toString().isNotEmpty)
                _buildInfoCard(
                  "Bio",
                  profil['bio'],
                  Icons.person,
                  const Color(0xFF2196F3),
                ),
              if (profil['parcours_academique'] != null &&
                  profil['parcours_academique'].toString().isNotEmpty)
                _buildInfoCard(
                  "Parcours académique",
                  profil['parcours_academique'],
                  Icons.school,
                  const Color(0xFF9C27B0),
                ),
              if (profil['experiences_professionnelles'] != null &&
                  profil['experiences_professionnelles'].toString().isNotEmpty)
                _buildInfoCard(
                  "Expériences professionnelles",
                  profil['experiences_professionnelles'],
                  Icons.work,
                  const Color(0xFFFF9800),
                ),
              if (profil['competences'] != null &&
                  profil['competences'].toString().isNotEmpty)
                _buildInfoCard(
                  "Compétences",
                  profil['competences'],
                  Icons.star,
                  const Color(0xFF4CAF50),
                ),
              if (profil['realisations'] != null &&
                  profil['realisations'].toString().isNotEmpty)
                _buildInfoCard(
                  "Réalisations",
                  profil['realisations'],
                  Icons.emoji_events,
                  const Color(0xFFF44336),
                ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
