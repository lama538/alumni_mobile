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
    NotificationService.initialize();
    loadEvents();
  }

  Future<void> loadEvents() async {
    setState(() => isLoading = true);
    try {
      final fetchedEvents = await service.getEvents(widget.userToken);

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur lors du chargement des événements'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<void> registerEvent(int eventId, Map<String, dynamic> eventData) async {
    try {
      debugPrint("👆 Tentative inscription à ${eventData['titre']} (ID=$eventId)");

      final response =
      await service.registerUser(eventId, widget.userId, widget.userToken);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Inscription réussie à "${eventData['titre']}"'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }

        final int confirmationId = eventId * 10 + 1;
        final int reminderId = eventId * 10 + 2;

        await NotificationService.showNotification(
          confirmationId,
          '🎉 Inscription confirmée',
          'Vous êtes inscrit à "${eventData['titre']}"',
        );

        final DateTime eventDate = DateTime.parse(eventData['date']);
        final DateTime reminderTime =
        eventDate.subtract(const Duration(minutes: 30));

        if (reminderTime.isAfter(DateTime.now())) {
          try {
            await NotificationService.scheduleNotification(
              id: reminderId,
              title: 'Rappel événement',
              body:
              "L'événement ${eventData['titre']} commence dans 30 minutes à ${eventData['lieu']}.",
              date: reminderTime,
            );
            debugPrint("🕒 Notification planifiée pour $reminderTime");
          } catch (e) {
            debugPrint("⚠️ Impossible de planifier la notification exacte : $e");
          }
        }
      } else if (response.statusCode == 400) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Vous êtes déjà inscrit à cet événement'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
              Text("Erreur lors de l'inscription : ${response.body}"),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      }
    } catch (err) {
      debugPrint("❌ Erreur inscription : $err");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur lors de l'inscription : $err"),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  String formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      return "${date.day.toString().padLeft(2, '0')}/"
          "${date.month.toString().padLeft(2, '0')}/"
          "${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return isoDate;
    }
  }

  String getMonthName(int month) {
    const months = [
      'JAN',
      'FÉV',
      'MAR',
      'AVR',
      'MAI',
      'JUN',
      'JUL',
      'AOÛ',
      'SEP',
      'OCT',
      'NOV',
      'DÉC'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text(
                'Événements',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              background: ColoredBox(color: Color(0xFF2563EB)),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 12),
                child: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.refresh_rounded,
                        color: Colors.white),
                  ),
                  onPressed: loadEvents,
                  tooltip: "Actualiser",
                ),
              ),
            ],
          ),
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF2563EB),
                  strokeWidth: 3,
                ),
              ),
            )
          else if (events.isEmpty)
            const SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Color(0xFFE0EAFF),
                      child: Icon(Icons.event_available_rounded,
                          size: 80, color: Color(0xFF2563EB)),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Aucun événement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Revenez plus tard',
                      style: TextStyle(
                        fontSize: 15,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildEventCard(events[index]),
                  childCount: events.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final eventDate = DateTime.parse(event['date']);
    final daysUntil = eventDate.difference(DateTime.now()).inDays;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 70,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0EAFF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getMonthName(eventDate.month),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        eventDate.day.toString(),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (daysUntil <= 7)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0EAFF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            daysUntil == 0
                                ? "Aujourd'hui"
                                : daysUntil == 1
                                ? "Demain"
                                : "Dans $daysUntil jours",
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        event['titre'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        event['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded,
                              size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Text(
                            '${eventDate.hour.toString().padLeft(2, '0')}:${eventDate.minute.toString().padLeft(2, '0')}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.location_on_rounded,
                              size: 16, color: Color(0xFF94A3B8)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              event['lieu'] ?? 'Lieu non précisé',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
              ),
            ),
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => registerEvent(event['id'], event),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  "S'inscrire",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding:
                  const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
