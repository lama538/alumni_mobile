// lib/screens/chat_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/ user.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';

class ChatScreen extends StatefulWidget {
  final int currentUserId;
  final String token;
  final User selectedUser;

  const ChatScreen({
    super.key,
    required this.currentUserId,
    required this.token,
    required this.selectedUser,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<AppMessage> messages = [];
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  bool isLoading = true;
  bool isSending = false;

  File? selectedMedia;
  String? selectedMediaType;
  VideoPlayerController? previewVideoController;
  Map<int, VideoPlayerController> videoControllers = {};

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    previewVideoController?.dispose();
    videoControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  Future<void> fetchMessages() async {
    try {
      final data = await MessageService.getMessages(widget.token, widget.selectedUser.id!);
      setState(() => messages = data);
      markMessagesRead();
    } catch (e) {
      debugPrint("Erreur fetch messages: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> markMessagesRead() async {
    try {
      await MessageService.markMessagesAsRead(widget.token, widget.selectedUser.id!);
      setState(() {
        for (var msg in messages) {
          if (msg.senderId == widget.selectedUser.id) msg.isRead = true;
        }
      });
    } catch (e) {
      debugPrint("Erreur mark read: $e");
    }
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

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty && selectedMedia == null) return;

    final tempMsg = AppMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      senderId: widget.currentUserId,
      receiverId: widget.selectedUser.id!,
      contenu: text,
      media: selectedMedia?.path,
      mediaType: selectedMediaType,
      isRead: false,
      senderName: "Moi",
      receiverName: widget.selectedUser.name,
      createdAt: DateTime.now(),
    );

    setState(() {
      messages.add(tempMsg);
      isSending = true;
    });

    messageController.clear();

    try {
      final sentMsg = await MessageService.sendMessageWithMedia(
        widget.token,
        widget.selectedUser.id!,
        text,
        selectedMedia,
      );

      setState(() {
        final index = messages.indexOf(tempMsg);
        if (index != -1) messages[index] = sentMsg;
        previewVideoController?.dispose();
        previewVideoController = null;
        selectedMedia = null;
        selectedMediaType = null;
        isSending = false;
      });

      Future.delayed(const Duration(milliseconds: 100), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    } catch (e) {
      debugPrint("Erreur envoi message: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Échec de l'envoi du message"),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      setState(() => isSending = false);
    }
  }

  void _showMediaFullScreen(AppMessage msg) {
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

  Widget _buildMessageItem(AppMessage msg) {
    final isMe = msg.senderId == widget.currentUserId;

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
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: 240,
              height: 180,
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
                    size: 56,
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
            borderRadius: BorderRadius.circular(16),
            child: Hero(
              tag: 'media_${msg.id}',
              child: msg.media!.startsWith('http')
                  ? Image.network(
                msg.media!,
                width: 240,
                height: 180,
                fit: BoxFit.cover,
              )
                  : Image.file(
                File(msg.media!),
                width: 240,
                height: 180,
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundImage: widget.selectedUser.photo != null &&
                  widget.selectedUser.photo!.isNotEmpty
                  ? NetworkImage(widget.selectedUser.photo!)
                  : const AssetImage('assets/images/avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    )
                        : null,
                    color: isMe ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(isMe ? 20 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (msg.contenu.isNotEmpty)
                        Text(
                          msg.contenu,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      if (msg.media != null && msg.contenu.isNotEmpty)
                        const SizedBox(height: 8),
                      if (msg.media != null) mediaWidget!,
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(msg.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                        size: 14,
                        color: msg.isRead ? const Color(0xFF3B82F6) : Colors.grey.shade400,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
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
                        controller: messageController,
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
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: widget.selectedUser.photo != null &&
                  widget.selectedUser.photo!.isNotEmpty
                  ? NetworkImage(widget.selectedUser.photo!)
                  : const AssetImage('assets/images/avatar.png') as ImageProvider,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.selectedUser.name,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'En ligne',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                : ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return _buildMessageItem(msg);
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
  final AppMessage message;
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
                  if (widget.message.contenu.isNotEmpty)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(left: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.message.contenu,
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