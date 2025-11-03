import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'actualite_details_screen.dart';
import 'AdminActualitesScreen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Widget pour afficher les vidéos
class VideoPlayerWidget extends StatefulWidget {
  final String url;
  const VideoPlayerWidget({required this.url, super.key});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.url)
      ..initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _controller,
          autoPlay: false,
          looping: false,
          showControls: true,
        );
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null && _controller.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    }
    return const Center(child: CircularProgressIndicator());
  }
}

class ActualitesScreen extends StatefulWidget {
  const ActualitesScreen({super.key});

  @override
  State<ActualitesScreen> createState() => _ActualitesScreenState();
}

class _ActualitesScreenState extends State<ActualitesScreen> {
  List<Map<String, dynamic>> actualites = [];
  bool isLoading = true;
  String? userToken;

  @override
  void initState() {
    super.initState();
    _loadUserToken();
  }

  Future<void> _loadUserToken() async {
    final prefs = await SharedPreferences.getInstance();
    userToken = prefs.getString('token');
    await _loadActualites();
  }

  Future<void> _loadActualites() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/actualites'),
        headers: {
          if (userToken != null) "Authorization": "Bearer $userToken",
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
    if (userToken == null) return;

    final liked = act['liked_by_user'] ?? false;
    final url = Uri.parse('http://10.0.2.2:8000/api/actualites/${act['id']}/like');
    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $userToken",
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

  void _goToAdminActualites() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminActualitesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Actualités",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2196F3),
          strokeWidth: 3,
        ),
      )
          : actualites.isEmpty
          ? Center(
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
      )
          : RefreshIndicator(
        onRefresh: _loadActualites,
        color: const Color(0xFF2196F3),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: actualites.length,
          itemBuilder: (context, index) {
            final act = actualites[index];

            final imageUrl = act['image']?.toString().isNotEmpty == true ? act['image'] : null;
            final videoUrl = act['video']?.toString().isNotEmpty == true ? act['video'] : null;

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
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
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
                      )
                    else if (videoUrl != null)
                      SizedBox(
                        height: 200,
                        width: double.infinity,
                        child: VideoPlayerWidget(url: videoUrl),
                      )
                    else
                      Container(
                        height: 200,
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: Icon(
                            Icons.article_outlined,
                            size: 60,
                            color: Color(0xFFBDBDBD),
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
                                radius: 16,
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
                              const SizedBox(width: 10),
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
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _goToAdminActualites,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }
}
