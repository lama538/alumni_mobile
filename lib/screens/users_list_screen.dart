import 'package:flutter/material.dart';
import '../services/user_service.dart';

class UsersListScreen extends StatefulWidget {
  final String type; // etudiants, alumni, entreprises, all

  const UsersListScreen({super.key, required this.type});

  @override
  State<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends State<UsersListScreen> {
  final UserService _userService = UserService();
  List<dynamic> users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);

    try {
      final data = await _userService.getUsersByType(widget.type);
      setState(() {
        users = data;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du chargement des utilisateurs")),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _toggleBlock(int id, int index) async {
    // on ne change pas encore l'état local, on attend la réponse de l'API
    final success = await _userService.toggleBlock(id);

    if (success != null) {
      setState(() {
        users[index]['isBlocked'] = success; // clé corrigée
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Impossible de changer le statut")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Liste - ${widget.type}"),
        backgroundColor: Colors.blue,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadUsers,
        child: ListView.builder(
          itemCount: users.length,
          itemBuilder: (_, index) {
            final u = users[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: u['isBlocked'] ? Colors.red : Colors.green,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(u['name']),
                subtitle: Text(u['email']),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: u['isBlocked'] ? Colors.green : Colors.red,
                  ),
                  onPressed: () => _toggleBlock(u['id'], index),
                  child: Text(
                    u['isBlocked'] ? "Débloquer" : "Bloquer",
                    style: const TextStyle(color: Colors.white),
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
