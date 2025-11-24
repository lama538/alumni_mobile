import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'actualite_details_screen.dart';
import 'AdminActualitesScreen.dart';
import 'calendar_screen.dart';
import 'offre_list_screen.dart';
import 'messaging_screen.dart';
import 'profil_screen.dart';
import 'UserProfilScreen.dart';

class EntrepriseHome extends StatefulWidget {
  const EntrepriseHome({super.key});

  @override
  State<EntrepriseHome> createState() => _EntrepriseHomeState();
}

class _EntrepriseHomeState extends State<EntrepriseHome> {
  String? userToken;
  int? userId;
  String? userPhoto;
  bool isLoading = true;
  int _currentIndex = 0;
  bool isSearching = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() {
        searchQuery = _searchController.text.trim();
      });
    });
  }

  String getUserPhotoUrl(String? photo) {
    if (photo == null || photo.isEmpty) return '';
    if (photo.startsWith('http')) return photo;
    return 'http://10.0.2.2:8000/storage/$photo';
  }

  ImageProvider getUserAvatar() {
    if (userPhoto != null && userPhoto!.isNotEmpty) {
      return NetworkImage(userPhoto!);
    } else {
      return const AssetImage('assets/images/default_avatar.png');
    }
  }

  Future<void> _loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final id = prefs.getInt('user_id');

    if (token == null || id == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/profile'),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profil = data['profil'];
        final user = data['user'];

        setState(() {
          userToken = token;
          userId = id;
          userPhoto = (user?['photo'] ?? profil?['photo'] ?? '').toString();
          isLoading = false;
        });
      } else {
        setState(() {
          userToken = token;
          userId = id;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        userToken = token;
        userId = id;
        isLoading = false;
      });
    }
  }

  void _onTabTapped(int index) {
    if (index == 2) {
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

  Future<void> _showLogoutDialog(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _logout(context);
    }
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
    }
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () async {
            final updatedPhoto = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfilScreen()),
            );
            if (updatedPhoto != null) await _loadUserData();
          },
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.grey[200],
            backgroundImage: getUserAvatar(),
          ),
        ),
      ),
      title: isSearching
          ? TextField(
        controller: _searchController,
        autofocus: true,
        style: const TextStyle(color: Color(0xFF1A1A1A)),
        decoration: const InputDecoration(
          hintText: "Rechercher...",
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.grey),
        ),
      )
          : SizedBox(
        height: 300,
        child: Center(
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(
            isSearching ? Icons.close : Icons.search,
            color: const Color(0xFF1A1A1A),
          ),
          onPressed: () {
            setState(() {
              isSearching = !isSearching;
              if (!isSearching) {
                searchQuery = '';
                _searchController.clear();
              }
            });
          },
        ),
        IconButton(
          icon: const Icon(Icons.message_outlined, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pushNamed(context, '/messages'),
        ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pushNamed(context, '/notifications'),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
          onSelected: (value) {
            if (value == 'logout') {
              _showLogoutDialog(context);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Déconnexion', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || userToken == null || userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screens = [
      ActualitesFeedScreen(userToken: userToken, searchQuery: searchQuery),
      CalendarScreen(userToken: userToken!, userId: userId!),
      const SizedBox(),
      const OffreListScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_currentIndex != 0) {
          setState(() => _currentIndex = 0);
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(context),
        body: screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home_outlined, Icons.home, "Accueil", 0),
                  _buildNavItem(Icons.event_outlined, Icons.event, "Événements", 1),
                  _buildAddButton(),
                  _buildNavItem(Icons.work_outline, Icons.work, "Offres", 3),
                ],
              ),
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
                color: isSelected ? const Color(0xFF7E57C2) : const Color(0xFF757575),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(0xFF7E57C2) : const Color(0xFF757575),
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
          color: const Color(0xFF7E57C2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7E57C2).withOpacity(0.25),
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

// ==================== ActualitesFeedScreen ====================
class ActualitesFeedScreen extends StatefulWidget {
  final String? userToken;
  final String searchQuery;

  const ActualitesFeedScreen({
    super.key,
    this.userToken,
    this.searchQuery = '',
  });

  @override
  State<ActualitesFeedScreen> createState() => _ActualitesFeedScreenState();
}

class _ActualitesFeedScreenState extends State<ActualitesFeedScreen> {
  List<Map<String, dynamic>> actualites = [];
  List<Map<String, dynamic>> profilsTrouves = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActualites();
    if (widget.searchQuery.isNotEmpty) {
      _searchProfiles(widget.searchQuery);
    }
  }

  @override
  void didUpdateWidget(covariant ActualitesFeedScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery) {
      _searchProfiles(widget.searchQuery);
    }
  }

  String getAuthorPhotoUrl(Map<String, dynamic>? auteur) {
    if (auteur == null) return '';
    String? photo = auteur['photo'] ?? auteur['profil']?['photo'];
    if (photo == null || photo.isEmpty) return '';
    if (photo.startsWith('http')) return photo;
    return 'http://10.0.2.2:8000/storage/$photo';
  }

  Future<void> _loadActualites() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/actualites'),
        headers: {
          if (widget.userToken != null)
            "Authorization": "Bearer ${widget.userToken}",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          actualites = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint("Erreur réseau: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _searchProfiles(String query) async {
    if (query.isEmpty) {
      setState(() => profilsTrouves = []);
      return;
    }

    try {
      final url = Uri.parse('http://10.0.2.2:8000/api/recherche-profils?q=$query');
      final resp = await http.get(url, headers: {
        if (widget.userToken != null)
          "Authorization": "Bearer ${widget.userToken}",
        "Accept": "application/json",
      });

      if (resp.statusCode == 200) {
        final List data = jsonDecode(resp.body);
        setState(() {
          profilsTrouves = data.map((e) => Map<String, dynamic>.from(e)).toList();
        });
      } else {
        setState(() => profilsTrouves = []);
      }
    } catch (e) {
      debugPrint("Erreur recherche profils: $e");
      setState(() => profilsTrouves = []);
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
      }
    } catch (e) {
      debugPrint("Erreur like: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredActualites = widget.searchQuery.isEmpty
        ? actualites
        : actualites.where((a) {
      final titre = (a['titre'] ?? '').toString().toLowerCase();
      final contenu = (a['contenu'] ?? '').toString().toLowerCase();
      final query = widget.searchQuery.toLowerCase();
      return titre.contains(query) || contenu.contains(query);
    }).toList();

    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF7E57C2),
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
      onRefresh: () async {
        await _loadActualites();
        if (widget.searchQuery.isNotEmpty) {
          await _searchProfiles(widget.searchQuery);
        }
      },
      color: const Color(0xFF7E57C2),
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          if (profilsTrouves.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                "Personnes",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: profilsTrouves.length,
                itemBuilder: (context, index) {
                  final p = profilsTrouves[index];
                  final photoUrl = getAuthorPhotoUrl(p);
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfilScreen(userId: p['id']),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      width: 75,
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: photoUrl.isNotEmpty
                                ? NetworkImage(photoUrl)
                                : const AssetImage('assets/images/default_avatar.png')
                            as ImageProvider,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            p['name'] ?? 'Utilisateur',
                            maxLines: 2,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
          ],
          if (widget.searchQuery.isNotEmpty && filteredActualites.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                "Actualités (${filteredActualites.length})",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ...filteredActualites.map((act) => _buildActualiteCard(act)),
        ],
      ),
    );
  }

  Widget _buildActualiteCard(Map<String, dynamic> act) {
    String? imageUrl = act['image'];
    String? videoUrl = act['video'];
    if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
      imageUrl = 'http://10.0.2.2:8000/storage/$imageUrl';
    }
    if (videoUrl != null && videoUrl.isNotEmpty && !videoUrl.startsWith('http')) {
      videoUrl = 'http://10.0.2.2:8000/storage/$videoUrl';
    }

    final date = act['created_at'] != null
        ? DateFormat('dd MMM yyyy').format(DateTime.parse(act['created_at']))
        : '';
    final auteur = act['auteur']?['name'] ?? 'Anonyme';
    final authorPhotoUrl = getAuthorPhotoUrl(act['auteur']);
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
            if (videoUrl != null && videoUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                height: 200,
                child: VideoPlayerWidget(videoUrl: videoUrl),
              )
            else if (imageUrl != null && imageUrl.isNotEmpty)
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
                      GestureDetector(
                        onTap: () {
                          if (act['auteur']?['id'] != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    UserProfilScreen(userId: act['auteur']['id']),
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.grey[300],
                          child: authorPhotoUrl.isNotEmpty
                              ? ClipOval(
                            child: Image.network(
                              authorPhotoUrl,
                              fit: BoxFit.cover,
                              width: 36,
                              height: 36,
                              errorBuilder: (_, __, ___) => Icon(
                                Icons.person,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                            ),
                          )
                              : Icon(
                            Icons.person,
                            color: Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (act['auteur']?['id'] != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          UserProfilScreen(userId: act['auteur']['id']),
                                    ),
                                  );
                                }
                              },
                              child: Text(
                                auteur,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1A1A1A),
                                  decoration: TextDecoration.underline,
                                ),
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
                  Container(height: 1, color: const Color(0xFFF0F0F0)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      InkWell(
                        onTap: () => _toggleLike(act),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                          child: Row(
                            children: [
                              Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? const Color(0xFFE91E63) : Colors.grey[600],
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
  }
}

// ==================== VideoPlayerWidget ====================
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl)
      ..initialize().then((_) {
        setState(() => isInitialized = true);
      });
    _controller.setLooping(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!isInitialized) {
      return Container(
        height: 200,
        color: Colors.black12,
        child: const Center(child: CircularProgressIndicator()),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying ? _controller.pause() : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller),
          if (!_controller.value.isPlaying)
            const Icon(Icons.play_arrow, color: Colors.white, size: 50),
        ],
      ),
    );
  }
}