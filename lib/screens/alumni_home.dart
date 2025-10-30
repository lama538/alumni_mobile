import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'actualite_details_screen.dart';
import 'AdminActualitesScreen.dart';
import 'calendar_screen.dart';
import 'group_list_screen.dart';
import 'offre_list_screen.dart';

class AlumniHome extends StatefulWidget {
  const AlumniHome({super.key});

  @override
  State<AlumniHome> createState() => _AlumniHomeState();
}

class _AlumniHomeState extends State<AlumniHome> {
  String? userToken;
  int? userId;
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userToken = prefs.getString('token');
      userId = prefs.getInt('user_id');
      isLoading = false;
    });
    debugPrint("📦 Token chargé : $userToken");
    debugPrint("📦 ID utilisateur : $userId");
  }

  void _onTabTapped(int index) {
    if (index == 2) {
      // Bouton central "+"
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AdminActualitesScreen()),
      );
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userToken == null || userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      ActualitesFeedScreen(userToken: userToken),
      CalendarScreen(userToken: userToken!, userId: userId!),
      const SizedBox(),
      const OffreListScreen(),
      GroupListScreen(userToken: userToken!, userId: userId!),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () {
              Navigator.pushNamed(context, '/alumniProfile');
            },
            child: CircleAvatar(
              backgroundColor: const Color(0xFF2196F3),
              child: const Icon(Icons.person, color: Colors.white, size: 24),
            ),
          ),
        ),
        title: const Text(
          "   ISI RELINK",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.message_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.pushNamed(context, '/messages');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A1A)),
            onPressed: () {
              Navigator.pushNamed(context, '/notifications');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, "Accueil", 0),
                _buildNavItem(Icons.event_outlined, Icons.event, "Événements", 1),
                _buildAddButton(),
                _buildNavItem(Icons.work_outline, Icons.work, "Offres", 3),
                _buildNavItem(Icons.group_outlined, Icons.group, "Groupes", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData outlinedIcon, IconData filledIcon, String label, int index) {
    final isSelected = _currentIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? filledIcon : outlinedIcon,
                color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF757575),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF2196F3) : const Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF2196F3),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2196F3).withOpacity(0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}

// Screen pour le fil d'actualités
class ActualitesFeedScreen extends StatefulWidget {
  final String? userToken;
  const ActualitesFeedScreen({super.key, this.userToken});

  @override
  State<ActualitesFeedScreen> createState() => _ActualitesFeedScreenState();
}

class _ActualitesFeedScreenState extends State<ActualitesFeedScreen> {
  List<Map<String, dynamic>> actualites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActualites();
  }

  Future<void> _loadActualites() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/actualites'),
        headers: {
          if (widget.userToken != null) "Authorization": "Bearer ${widget.userToken}",
          "Accept": "application/json",
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          actualites = List<Map<String, dynamic>>.from(data);
        });
      } else {
        debugPrint('Erreur chargement actualités: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Erreur réseau: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleLike(Map<String, dynamic> act) async {
    if (widget.userToken == null) return;
    final liked = act['liked_by_user'] ?? false;
    final url = Uri.parse('http://10.0.2.2:8000/api/actualites/${act['id']}/like');
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer ${widget.userToken}",
          "Accept": "application/json",
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          act['liked_by_user'] = !liked;
          act['likes_count'] = (act['likes_count'] ?? 0) + (!liked ? 1 : -1);
        });
      } else {
        debugPrint('Erreur like: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint("Erreur like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
          strokeWidth: 3,
        ),
      );
    }

    if (actualites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 80,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              "Aucune actualité disponible",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadActualites,
      color: const Color(0xFF2196F3),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: actualites.length,
        itemBuilder: (context, index) {
          final act = actualites[index];
          final imageUrl = act['image']?.toString().isNotEmpty == true ? act['image'] : null;
          final date = act['created_at'] != null
              ? DateFormat('dd MMM yyyy').format(DateTime.parse(act['created_at']))
              : '';
          final auteur = act['auteur']?['name'] ?? 'Anonyme';
          final liked = act['liked_by_user'] ?? false;
          final likesCount = act['likes_count'] ?? 0;
          final commentsCount = act['comments_count'] ?? 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 60,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: const Color(0xFF2196F3),
                              child: Text(
                                auteur[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    auteur,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          act['titre'] ?? '',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          act['contenu']?.length > 120
                              ? '${act['contenu'].substring(0, 120)}...'
                              : act['contenu'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 1,
                          color: const Color(0xFFF0F0F0),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(
                              onTap: () => _toggleLike(act),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      liked
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color: liked
                                          ? const Color(0xFFE91E63)
                                          : Colors.grey[600],
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$likesCount",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ActualiteDetailsScreen(actualite: act),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.chat_bubble_outline,
                                      color: Colors.grey[600],
                                      size: 22,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$commentsCount",
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}