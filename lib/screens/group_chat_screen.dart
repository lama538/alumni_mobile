import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../services/api_service.dart';
import '../models/group_message.dart';
import 'group_detail_screen.dart';

class GroupChatScreen extends StatefulWidget {
  final String userToken;
  final int userId;
  final int groupId;
  final String groupName;
  final int creatorId;

  const GroupChatScreen({
    super.key,
    required this.userToken,
    required this.userId,
    required this.groupId,
    required this.groupName,
    required this.creatorId,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  List<GroupMessage> messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = true;
  bool isSending = false;

  File? selectedMedia;
  String? selectedMediaType;
  VideoPlayerController? previewVideoController;
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    previewVideoController?.dispose();
    videoControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> pickMedia() async {
    final picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.image_rounded, color: Color(0xFF3B82F6)),
                ),
                title: const Text('Image', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    setState(() {
                      selectedMedia = File(pickedFile.path);
                      selectedMediaType = "image";
                      previewVideoController?.dispose();
                      previewVideoController = null;
                    });
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC4899).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.videocam_rounded, color: Color(0xFFEC4899)),
                ),
                title: const Text('Vidéo', style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () async {
                  Navigator.pop(context);
                  final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
                  if (pickedFile != null) {
                    previewVideoController?.dispose();
                    previewVideoController = VideoPlayerController.file(File(pickedFile.path))
                      ..initialize().then((_) {
                        setState(() {});
                      });
                    setState(() {
                      selectedMedia = File(pickedFile.path);
                      selectedMediaType = "video";
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> loadMessages() async {
    setState(() => isLoading = true);

    try {
      final msgs = await ApiService.getGroupMessages(widget.userToken, widget.groupId);

      setState(() {
        messages = msgs;
        isLoading = false;
      });

      scrollToBottom();
    } catch (e) {
      debugPrint("Erreur chargement messages: $e");
      setState(() => isLoading = false);
    }
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty && selectedMedia == null) return;

    setState(() {
      _controller.clear();
      isSending = true;
    });

    try {
      final msg = await ApiService.sendGroupMessage(
        widget.userToken,
        widget.groupId,
        text,
        mediaPath: selectedMedia?.path,
        mediaType: selectedMediaType,
      );

      setState(() {
        messages.add(msg);
        selectedMedia = null;
        selectedMediaType = null;
        previewVideoController?.dispose();
        previewVideoController = null;
        isSending = false;
      });

      scrollToBottom();
    } catch (e) {
      debugPrint("Erreur envoi message: $e");
      setState(() => isSending = false);
    }
  }

  void _showMediaFullScreen(GroupMessage msg) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: _MediaFullScreenView(
              message: msg,
              videoControllers: videoControllers,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(GroupMessage msg) {
    Widget? mediaWidget;

    if (msg.media != null) {
      if (msg.mediaType == "video") {
        if (!videoControllers.containsKey(msg.id)) {
          final controller = msg.media!.startsWith('http')
              ? VideoPlayerController.network(msg.media!)
              : VideoPlayerController.file(File(msg.media!));
          controller.initialize().then((_) => setState(() {}));
          videoControllers[msg.id] = controller;
        }
        final controller = videoControllers[msg.id]!;

        mediaWidget = GestureDetector(
          onTap: () => _showMediaFullScreen(msg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 220,
              height: 160,
              color: Colors.black,
              child: controller.value.isInitialized
                  ? Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: controller.value.aspectRatio,
                    child: VideoPlayer(controller),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  Icon(
                    controller.value.isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_filled,
                    size: 48,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ],
              )
                  : const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
        );
      } else {
        mediaWidget = GestureDetector(
          onTap: () => _showMediaFullScreen(msg),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Hero(
              tag: 'media_${msg.id}',
              child: msg.media!.startsWith('http')
                  ? Image.network(
                msg.media!,
                width: 220,
                height: 160,
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(msg.media!),
                width: 220,
                height: 160,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEFF6FF),
            child: Text(
              msg.senderName.isNotEmpty ? msg.senderName[0].toUpperCase() : '?',
              style: const TextStyle(
                color: Color(0xFF3B82F6),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      msg.senderName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(msg.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.message.isNotEmpty)
                        Text(
                          msg.message,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: Color(0xFF334155),
                          ),
                        ),
                      if (msg.media != null && msg.message.isNotEmpty)
                        const SizedBox(height: 8),
                      if (msg.media != null) mediaWidget!,
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewMedia() {
    if (selectedMedia == null) return const SizedBox.shrink();

    if (selectedMediaType == "video" && previewVideoController != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          height: 150,
          color: Colors.black,
          child: previewVideoController!.value.isInitialized
              ? Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: previewVideoController!.value.aspectRatio,
                child: VideoPlayer(previewVideoController!),
              ),
              Icon(
                previewVideoController!.value.isPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                size: 48,
                color: Colors.white.withOpacity(0.9),
              ),
            ],
          )
              : const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          selectedMedia!,
          width: 200,
          height: 150,
          fit: BoxFit.cover,
        ),
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            children: [
              if (selectedMedia != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Stack(
                    children: [
                      _buildPreviewMedia(),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedMedia = null;
                              selectedMediaType = null;
                              previewVideoController?.dispose();
                              previewVideoController = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.add_rounded, color: Color(0xFF3B82F6)),
                      onPressed: pickMedia,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Message...",
                          hintStyle: TextStyle(color: Colors.grey),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: isSending
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                          : const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: isSending ? null : sendMessage,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GroupDetailScreen(
                  userToken: widget.userToken,
                  userId: widget.userId,
                  groupId: widget.groupId,
                  groupName: widget.groupName,
                  creatorId: widget.creatorId,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.group_rounded,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Appuyez pour voir les détails',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isLoading
                ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            )
                : messages.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 60,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Aucun message',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Soyez le premier à écrire !',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessageBubble(messages[index]);
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }
}

class _MediaFullScreenView extends StatefulWidget {
  final GroupMessage message;
  final Map<int, VideoPlayerController> videoControllers;

  const _MediaFullScreenView({
    required this.message,
    required this.videoControllers,
  });

  @override
  State<_MediaFullScreenView> createState() => _MediaFullScreenViewState();
}

class _MediaFullScreenViewState extends State<_MediaFullScreenView> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.message.mediaType == "video") {
      _controller = widget.videoControllers[widget.message.id];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: widget.message.mediaType == "video" && _controller != null
                ? _controller!.value.isInitialized
                ? GestureDetector(
              onTap: () {
                setState(() {
                  if (_controller!.value.isPlaying) {
                    _controller!.pause();
                  } else {
                    _controller!.play();
                  }
                });
              },
              child: AspectRatio(
                aspectRatio: _controller!.value.aspectRatio,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_controller!),
                    if (!_controller!.value.isPlaying)
                      Icon(
                        Icons.play_circle_filled,
                        size: 80,
                        color: Colors.white.withOpacity(0.9),
                      ),
                  ],
                ),
              ),
            )
                : const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            )
                : InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: 'media_${widget.message.id}',
                child: widget.message.media!.startsWith('http')
                    ? Image.network(widget.message.media!)
                    : Image.file(File(widget.message.media!)),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  if (widget.message.message.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.message.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}