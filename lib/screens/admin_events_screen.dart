import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminEventsScreen extends StatefulWidget {
  const AdminEventsScreen({super.key});

  @override
  State<AdminEventsScreen> createState() => _AdminEventsScreenState();
}

class _AdminEventsScreenState extends State<AdminEventsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descController = TextEditingController();
  final _lieuController = TextEditingController();
  DateTime? _selectedDate;
  String? _token;
  List events = [];

  int? _editingEventId;

  @override
  void initState() {
    super.initState();
    _loadTokenAndEvents();
  }

  Future<void> _loadTokenAndEvents() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    if (_token != null) {
      _loadEvents();
    }
  }

  Future<void> _loadEvents() async {
    if (_token == null) return;
    try {
      final fetchedEvents = await ApiService.getEvents(_token!);
      setState(() {
        events = fetchedEvents;
      });
    } catch (e) {
      print("Erreur load events: $e");
    }
  }

  Future<void> _createOrUpdateEvent() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && _token != null) {
      final eventData = {
        "titre": _titreController.text,
        "description": _descController.text,
        "date": _selectedDate!.toIso8601String(),
        "lieu": _lieuController.text
      };

      try {
        if (_editingEventId != null) {
          // Modifier événement
          await ApiService.updateEvent(_token!, _editingEventId!, eventData);
          _editingEventId = null;
        } else {
          // Créer événement
          await ApiService.createEvent(_token!, eventData);
        }

        _titreController.clear();
        _descController.clear();
        _lieuController.clear();
        _selectedDate = null;
        _loadEvents();
      } catch (e) {
        print("Erreur create/update event: $e");
      }
    }
  }

  Future<void> _deleteEvent(int id) async {
    if (_token == null) return;
    try {
      await ApiService.deleteEvent(_token!, id);
      _loadEvents();
    } catch (e) {
      print("Erreur delete event: $e");
    }
  }

  void _startEdit(Map event) {
    _titreController.text = event['titre'];
    _descController.text = event['description'];
    _lieuController.text = event['lieu'];
    _selectedDate = DateTime.parse(event['date']);
    _editingEventId = event['id'];
    setState(() {});
  }

  Future<void> _showParticipants(int eventId) async {
    if (_token == null) return;
    try {
      final participants = await ApiService.getEventParticipants(_token!, eventId);

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text("Participants à l'événement"),
            content: participants.isEmpty
                ? const Text("Aucun participant pour cet événement.")
                : SizedBox(
              width: double.maxFinite,
              height: 300, // ✅ Hauteur fixe pour le scroll
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(), // ✅ Scroll activé
                itemCount: participants.length,
                itemBuilder: (context, index) {
                  final p = participants[index];
                  return ListTile(
                    leading: const Icon(Icons.person),
                    title: Text(p['name'] ?? 'Nom inconnu'),
                    subtitle: Text(p['email'] ?? 'Email non disponible'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Fermer"),
              ),
            ],
          );
        },
      );
    } catch (e) {
      print("Erreur show participants: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des participants")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des événements")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _titreController,
                    decoration: const InputDecoration(labelText: "Titre"),
                    validator: (v) => v!.isEmpty ? "Titre requis" : null,
                  ),
                  TextFormField(
                    controller: _descController,
                    decoration: const InputDecoration(labelText: "Description"),
                    validator: (v) => v!.isEmpty ? "Description requise" : null,
                  ),
                  TextFormField(
                    controller: _lieuController,
                    decoration: const InputDecoration(labelText: "Lieu"),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(_selectedDate == null
                          ? "Date non sélectionnée"
                          : DateFormat("dd/MM/yyyy HH:mm").format(_selectedDate!)),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                          );
                          if (date != null) {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
                            );
                            if (time != null) {
                              _selectedDate = DateTime(
                                date.year,
                                date.month,
                                date.day,
                                time.hour,
                                time.minute,
                              );
                              setState(() {});
                            }
                          }
                        },
                        child: const Text("Choisir date"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _createOrUpdateEvent,
                    child: Text(_editingEventId != null ? "Modifier" : "Créer"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                final e = events[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(e['titre'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e['description']),
                        const SizedBox(height: 5),
                        Text("📍 ${e['lieu'] ?? 'Lieu non précisé'}"),
                        Text(
                          "🗓️ ${DateFormat("dd/MM/yyyy HH:mm").format(DateTime.parse(e['date']))}",
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => _showParticipants(e['id']),
                              icon: const Icon(Icons.people),
                              label: const Text("Voir participants"),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEdit(e),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteEvent(e['id']),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
