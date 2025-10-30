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
          const SnackBar(content: Text('Erreur lors du chargement des notifications')),
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
    try {
      await ApiService.clearReadNotifications(token);
      await _fetchNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notifications lues supprimées')),
        );
      }
    } catch (e) {
      debugPrint('Erreur suppression notifications lues: $e');
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'message':
        return Icons.message;
      case 'offre':
        return Icons.work;
      case 'rappel':
        return Icons.notifications_active;
      default:
        return Icons.notifications;
    }
  }

  Color _getTileColor(bool isRead) => isRead ? Colors.grey.shade200 : Colors.blue.shade50;

  String _getDisplayText(AppNotification notif) {
    final body = notif.body.isNotEmpty ? notif.body : 'Aucun contenu';
    switch (notif.type) {
      case 'message':
        final senderName = notif.sender ?? 'quelqu’un';
        return "De $senderName : $body";
      case 'offre':
        return "Offre : $body";
      case 'rappel':
        return "Rappel : $body";
      default:
        return body;
    }
  }

  void _showNotificationDetail(AppNotification notif) {
    _markAsRead(notif);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(notif.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_getDisplayText(notif)),
            const SizedBox(height: 10),
            Text(
              "Reçue le : ${notif.createdAt.toLocal().toString().substring(0, 16)}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Rafraîchir',
            onPressed: _fetchNotifications,
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Supprimer les notifications lues',
            onPressed: _clearReadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(
        child: Text(
          'Aucune notification pour le moment',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : RefreshIndicator(
        onRefresh: _fetchNotifications,
        child: ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notif = notifications[index];
            return Card(
              color: _getTileColor(notif.isRead),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: notif.isRead ? Colors.grey : Colors.blueAccent,
                  child: Icon(_getIcon(notif.type), color: Colors.white),
                ),
                title: Text(
                  notif.title,
                  style: TextStyle(fontWeight: notif.isRead ? FontWeight.normal : FontWeight.bold),
                ),
                subtitle: Text(_getDisplayText(notif), maxLines: 2, overflow: TextOverflow.ellipsis),
                trailing: notif.isRead ? null : const Icon(Icons.fiber_new, color: Colors.red),
                onTap: () => _showNotificationDetail(notif),
              ),
            );
          },
        ),
      ),
    );
  }
}
