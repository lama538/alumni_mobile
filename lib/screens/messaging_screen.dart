import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ user.dart';
import '../models/message_model.dart';
import '../services/message_service.dart';
import 'chat_screen.dart';

class MessagingScreen extends StatefulWidget {
  const MessagingScreen({super.key});

  @override
  State<MessagingScreen> createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  String token = '';
  int currentUserId = 0;
  List<AppMessage> messages = [];
  List<User> senders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadToken();
  }

  Future<void> loadToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      currentUserId = prefs.getInt('user_id') ?? 0;
    });
    fetchReceivedMessages();
  }

  Future<void> fetchReceivedMessages() async {
    setState(() => isLoading = true);
    try {
      final data = await MessageService.getReceivedMessages(token);
      setState(() => messages = data);

      final uniqueSenders = <int, User>{};
      for (var msg in data) {
        // Vérifier si l'utilisateur existe déjà, sinon créer un nouvel objet User
        if (!uniqueSenders.containsKey(msg.senderId)) {
          uniqueSenders[msg.senderId] = User(
            id: msg.senderId,
            name: msg.senderName,
            role: 'alumni',
            email: msg.senderEmail ?? '',
            photo: msg.senderPhoto, // Photo du message
          );
        }
      }
      setState(() => senders = uniqueSenders.values.toList());
    } catch (e) {
      debugPrint("Erreur fetch messages: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  void openChat(User user) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          currentUserId: currentUserId,
          token: token,
          selectedUser: user,
        ),
      ),
    );
    // Rafraîchir les messages après le retour du chat
    fetchReceivedMessages();
  }

  Future<void> newConversation() async {
    try {
      final users = await MessageService.getUsers(token);

      User? selected = await showDialog<User>(
        context: context,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            constraints: const BoxConstraints(maxHeight: 600),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.person_add_rounded, color: Colors.white, size: 28),
                      SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          "Nouvelle conversation",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Icon(Icons.close, color: Colors.white70),
                    ],
                  ),
                ),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return InkWell(
                        onTap: () => Navigator.pop(context, user),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 28,
                                    backgroundColor: Colors.grey.shade200,
                                    backgroundImage: user.photo != null && user.photo!.isNotEmpty
                                        ? NetworkImage(user.photo!)
                                        : null,
                                    child: user.photo == null || user.photo!.isEmpty
                                        ? Text(
                                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    )
                                        : null,
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user.role,
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      if (selected != null) openChat(selected);
    } catch (e) {
      debugPrint("Erreur nouvelle conversation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Impossible de charger les utilisateurs"),
            ],
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour.toString().padLeft(2, '0');
      final minute = dateTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[dateTime.weekday - 1];
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Messages",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: false,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.white),
              onPressed: newConversation,
            ),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
        ),
      )
          : senders.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        color: const Color(0xFF3B82F6),
        onRefresh: fetchReceivedMessages,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: senders.length,
          itemBuilder: (context, index) {
            final sender = senders[index];
            final unreadCount = messages
                .where((m) => m.senderId == sender.id && !m.isRead)
                .length;
            final lastMessage = messages
                .where((m) => m.senderId == sender.id)
                .isNotEmpty
                ? messages
                .where((m) => m.senderId == sender.id)
                .reduce((a, b) =>
            a.createdAt.isAfter(b.createdAt) ? a : b)
                : null;
            return _buildConversationCard(sender, unreadCount, lastMessage);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 80,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Aucune conversation",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Commencez une nouvelle conversation",
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: newConversation,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text(
                "Nouvelle conversation",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(User sender, int unreadCount, AppMessage? lastMessage) {
    String lastMessageText = 'Aucun message';
    if (lastMessage != null) {
      if (lastMessage.media != null && lastMessage.mediaType == "image") {
        lastMessageText = '📷 Image';
      } else if (lastMessage.media != null && lastMessage.mediaType == "video") {
        lastMessageText = '🎥 Vidéo';
      } else if (lastMessage.contenu.isNotEmpty) {
        lastMessageText = lastMessage.contenu;
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openChat(sender),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: unreadCount > 0
                              ? const Color(0xFF3B82F6)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: sender.photo != null && sender.photo!.isNotEmpty
                            ? NetworkImage(sender.photo!)
                            : null,
                        onBackgroundImageError: sender.photo != null && sender.photo!.isNotEmpty
                            ? (exception, stackTrace) {
                          debugPrint("Erreur chargement image: $exception");
                        }
                            : null,
                        child: sender.photo == null || sender.photo!.isEmpty
                            ? Text(
                          sender.name.isNotEmpty ? sender.name[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF3B82F6),
                          ),
                        )
                            : null,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              sender.name,
                              style: TextStyle(
                                fontWeight: unreadCount > 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (lastMessage != null)
                            Text(
                              _formatTime(lastMessage.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: unreadCount > 0
                                    ? const Color(0xFF3B82F6)
                                    : Colors.grey.shade600,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              lastMessageText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: unreadCount > 0
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                                fontSize: 14,
                                fontWeight: unreadCount > 0
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(12)),
                              ),
                              child: Text(
                                unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
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
        ),
      ),
    );
  }
}