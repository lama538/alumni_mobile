import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<AppNotification> notifications = [];
  String token = '';
  bool isLoading = true;
  Timer? refreshTimer;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token') ?? '';
    if (token.isEmpty) return;

    await _fetchNotifications();

    refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _fetchNotifications();
    });
  }

  Future<void> _fetchNotifications() async {
    if (token.isEmpty) return;

    if (mounted) setState(() => isLoading = true);
    try {
      final data = await ApiService.getNotifications(token);
      if (mounted) setState(() => notifications = data);
    } catch (e) {
      debugPrint('Erreur récupération notifications: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Erreur lors du chargement'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _markAsRead(AppNotification notif) async {
    if (!notif.isRead && token.isNotEmpty) {
      try {
        await ApiService.markNotificationRead(token, notif.id);
        if (mounted) setState(() => notif.isRead = true);
      } catch (e) {
        debugPrint('Erreur mark as read: $e');
      }
    }
  }

  Future<void> _clearReadNotifications() async {
    if (token.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirmation'),
        content: const Text('Supprimer toutes les notifications lues ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ApiService.clearReadNotifications(token);
      await _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Notifications lues supprimées'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur suppression notifications lues: $e');
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.chat_bubble_rounded;
      case 'offre':
        return Icons.work_rounded;
      case 'evenement':
        return Icons.event_rounded;
      case 'rappel':
        return Icons.notifications_active_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getIconColor(String type) {
    switch (type) {
      case 'message':
        return const Color(0xFF3B82F6);
      case 'offre':
        return const Color(0xFF10B981);
      case 'evenement':
        return const Color(0xFFF59E0B);
      case 'rappel':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getDisplayText(AppNotification notif) {
    final body = notif.body.isNotEmpty ? notif.body : 'Aucun contenu';
    final senderName = notif.sender ?? 'quelqu\'un';

    switch (notif.type) {
      case 'message':
        return "Vous avez reçu un nouveau message de $senderName : $body";
      case 'offre':
        return "Vous avez reçu une nouvelle offre : $body";
      case 'evenement':
        return "Vous avez reçu un nouvel événement : $body";
      case 'rappel':
        return "Rappel : $body";
      default:
        return body;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'Il y a ${difference.inHours}h';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      final day = dateTime.day.toString().padLeft(2, '0');
      final month = dateTime.month.toString().padLeft(2, '0');
      return '$day/$month/${dateTime.year}';
    }
  }

  void _showNotificationDetail(AppNotification notif) {
    _markAsRead(notif);
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _getIconColor(notif.type).withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _getIconColor(notif.type),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        _getIcon(notif.type),
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            notif.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(notif.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  _getDisplayText(notif),
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getIconColor(notif.type),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            if (unreadCount > 0)
              Text(
                '$unreadCount non ${unreadCount > 1 ? 'lues' : 'lue'}',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
            tooltip: 'Rafraîchir',
            onPressed: _fetchNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.black87),
            tooltip: 'Supprimer les lues',
            onPressed: _clearReadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
        ),
      )
          : notifications.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_off_rounded,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Aucune notification',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous êtes à jour !',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        color: const Color(0xFF3B82F6),
        onRefresh: _fetchNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: !notif.isRead
                      ? _getIconColor(notif.type).withOpacity(0.3)
                      : Colors.transparent,
                  width: 2,
                ),
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
                  onTap: () => _showNotificationDetail(notif),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _getIconColor(notif.type).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(notif.type),
                            color: _getIconColor(notif.type),
                            size: 24,
                          ),
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
                                      notif.title,
                                      style: TextStyle(
                                        fontWeight: !notif.isRead
                                            ? FontWeight.bold
                                            : FontWeight.w600,
                                        fontSize: 16,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (!notif.isRead)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _getIconColor(notif.type),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _getDisplayText(notif),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: !notif.isRead
                                      ? Colors.black87
                                      : Colors.grey.shade600,
                                  fontSize: 14,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(notif.createdAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
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
          },
        ),
      ),
    );
  }
}