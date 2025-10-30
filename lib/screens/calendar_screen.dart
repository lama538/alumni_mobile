import 'package:flutter/material.dart';
import '../services/event_service.dart';
import '../services/notification_service.dart';

class CalendarScreen extends StatefulWidget {
  final String userToken;
  final int userId;

  const CalendarScreen({
    super.key,
    required this.userToken,
    required this.userId,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late EventService service;
  List<Map<String, dynamic>> events = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    service = EventService(baseUrl: 'http://10.0.2.2:8000');
    NotificationService.initialize(); // Initialisation notifications
    loadEvents();
  }

  /// 🔹 Chargement des événements depuis l’API
  Future<void> loadEvents() async {
    try {
      final fetchedEvents = await service.getEvents(widget.userToken);

      // ⚡ Filtrer événements passés
      final upcomingEvents = fetchedEvents
          .where((e) => DateTime.parse(e['date']).isAfter(DateTime.now()))
          .toList();

      debugPrint("✅ Événements à venir: ${upcomingEvents.length}");
      setState(() {
        events = List<Map<String, dynamic>>.from(upcomingEvents);
        isLoading = false;
      });
    } catch (e) {
      debugPrint("❌ Erreur chargement événements : $e");
      setState(() {
        events = [];
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors du chargement des événements.')),
      );
    }
  }

  /// 🔹 Inscription à un événement + notifications
  /// 🔹 Inscription à un événement + notifications
  Future<void> registerEvent(int eventId, Map<String, dynamic> eventData) async {
    try {
      debugPrint("👆 Tentative inscription à ${eventData['titre']} (ID=$eventId)");

      // 🔹 Appel API pour s'inscrire
      final response = await service.registerUser(eventId, widget.userId, widget.userToken);

      // 🔹 Vérifier la réponse
      if (response.statusCode == 200 || response.statusCode == 201) {
        // ✅ Inscription réussie
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Inscription réussie à "${eventData['titre']}"')),
        );

        // 🔹 Notifications
        final int confirmationId = eventId * 10 + 1;
        final int reminderId = eventId * 10 + 2;

        await NotificationService.showNotification(
          confirmationId,
          '🎉 Inscription confirmée',
          'Vous êtes inscrit à "${eventData['titre']}"',
        );

        final DateTime eventDate = DateTime.parse(eventData['date']);
        final DateTime reminderTime = eventDate.subtract(const Duration(minutes: 30));
        if (reminderTime.isAfter(DateTime.now())) {
          try {
            await NotificationService.scheduleNotification(
              id: reminderId,
              title: '📅 Rappel événement',
              body: 'L’événement "${eventData['titre']}" commence dans 30 minutes à ${eventData['lieu']}.',
              date: reminderTime,
            );
            debugPrint("🕒 Notification planifiée pour $reminderTime");
          } catch (e) {
            debugPrint("⚠️ Impossible de planifier la notification exacte : $e");
          }
        }
      } else if (response.statusCode == 400) {
        // 🔹 Déjà inscrit
        final errorData = response.body;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Vous êtes déjà inscrit à cet événement.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        // 🔹 Autres erreurs
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l’inscription : ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (err) {
      debugPrint("❌ Erreur inscription : $err");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l’inscription : $err')),
      );
    }
  }





  /// 🔹 Formatage date
  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎓 Événements à venir'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : events.isEmpty
          ? const Center(
          child: Text(
            'Aucun événement disponible pour le moment.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ))
          : RefreshIndicator(
        onRefresh: loadEvents,
        child: ListView.builder(
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                title: Text(
                  e['titre'],
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    "${e['description']}\n📍 Lieu : ${e['lieu']}\n📅 Date : ${formatDate(e['date'])}",
                  ),
                ),
                trailing: ElevatedButton(
                  onPressed: () => registerEvent(e['id'], e),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text("S’inscrire"),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
