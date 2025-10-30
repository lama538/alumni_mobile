import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';

class ActualiteDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> actualite;

  const ActualiteDetailsScreen({super.key, required this.actualite});

  @override
  State<ActualiteDetailsScreen> createState() => _ActualiteDetailsScreenState();
}

class _ActualiteDetailsScreenState extends State<ActualiteDetailsScreen> {
  late bool likedByUser;
  late int likesCount;
  late int commentsCount;
  VideoPlayerController? _videoController;

  List<Map<String, dynamic>> commentaires = [];
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    likedByUser = widget.actualite['liked_by_user'] ?? false;
    likesCount = widget.actualite['likes_count'] ?? 0;
    commentsCount = widget.actualite['comments_count'] ?? 0;

    var rawComments = widget.actualite['commentaires'];
    if (rawComments is String) {
      try {
        rawComments = jsonDecode(rawComments);
      } catch (e) {
        rawComments = [];
      }
    }
    commentaires = List<Map<String, dynamic>>.from(rawComments ?? []);

    // Vidéo avec lecture automatique et boucle
    if (widget.actualite['video'] != null &&
        widget.actualite['video'].toString().isNotEmpty) {
      _videoController = VideoPlayerController.network(widget.actualite['video'])
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play(); // lecture automatique
          _videoController!.setLooping(true); // boucle
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void toggleLike() {
    setState(() {
      likedByUser = !likedByUser;
      likesCount += likedByUser ? 1 : -1;
    });
  }

  Future<void> sendComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vous devez être connecté pour commenter"),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final url = Uri.parse(
        'http://10.0.2.2:8000/api/actualites/${widget.actualite['id']}/comment');
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $token",
        "Accept": "application/json",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"contenu": _commentController.text}),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final updatedComments = data['commentaires'] ?? [];

      setState(() {
        commentaires = List<Map<String, dynamic>>.from(updatedComments);
        commentsCount = data['comments_count'] ?? commentaires.length;
        _commentController.clear();
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Impossible d'envoyer le commentaire"),
          backgroundColor: Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.actualite['image']?.toString().isNotEmpty == true
        ? widget.actualite['image']
        : null;

    final date = widget.actualite['created_at'] != null
        ? DateFormat('dd MMMM yyyy')
        .format(DateTime.parse(widget.actualite['created_at']))
        : '';

    final auteur = widget.actualite['auteur']?['name'] ?? 'Anonyme';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A1A)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A1A)),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image ou Vidéo
                  if (imageUrl != null)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 280,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 280,
                        color: const Color(0xFFF0F0F0),
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 80,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      ),
                    )
                  else if (_videoController != null)
                    _videoController!.value.isInitialized
                        ? Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              _videoController!.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.white,
                              size: 40,
                            ),
                            onPressed: () {
                              setState(() {
                                _videoController!.value.isPlaying
                                    ? _videoController!.pause()
                                    : _videoController!.play();
                              });
                            },
                          ),
                        ),
                      ],
                    )
                        : Container(
                      height: 280,
                      color: Colors.black12,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),

                  // Contenu principal
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Auteur et date
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: const Color(0xFF2196F3),
                              child: Text(
                                auteur[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  Text(
                                    date,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Titre
                        Text(
                          widget.actualite['titre'] ?? '',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Contenu
                        Text(
                          widget.actualite['contenu'] ?? '',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Statistiques et actions
                        Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 0),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.grey[200]!),
                              bottom: BorderSide(color: Colors.grey[200]!),
                            ),
                          ),
                          child: Row(
                            children: [
                              InkWell(
                                onTap: toggleLike,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        likedByUser
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: likedByUser
                                            ? const Color(0xFFE91E63)
                                            : Colors.grey[600],
                                        size: 24,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "$likesCount",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Row(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    color: Colors.grey[600],
                                    size: 24,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "$commentsCount",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey[700],
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

                  const SizedBox(height: 8),

                  // Section commentaires
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Commentaires ($commentsCount)",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (commentaires.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.chat_bubble_outline,
                                    size: 60,
                                    color: Colors.grey[300],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Aucun commentaire",
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Soyez le premier à commenter",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
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
                            itemCount: commentaires.length,
                            itemBuilder: (context, index) {
                              final comment = commentaires[index];
                              final userName = comment['user_name'] ?? 'Utilisateur';
                              final contenu = comment['contenu'] ?? '';

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: const Color(0xFF2196F3),
                                      child: Text(
                                        userName[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF5F5F5),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              userName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(contenu),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Input commentaire
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Ajouter un commentaire...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                      fillColor: const Color(0xFFF0F0F0),
                      filled: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: sendComment,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
