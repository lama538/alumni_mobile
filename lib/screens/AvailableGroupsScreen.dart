import 'package:flutter/material.dart';
import '../services/group_service.dart';

class AvailableGroupsScreen extends StatefulWidget {
  final String userToken;
  final int userId;

  const AvailableGroupsScreen({super.key, required this.userToken, required this.userId});

  @override
  State<AvailableGroupsScreen> createState() => _AvailableGroupsScreenState();
}

class _AvailableGroupsScreenState extends State<AvailableGroupsScreen> {
  late GroupService service;
  List<Map<String, dynamic>> groups = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    service = GroupService(baseUrl: 'http://10.0.2.2:8000/api');
    loadGroups();
  }

  Future<void> loadGroups() async {
    setState(() => isLoading = true);
    try {
      final fetchedGroups = await service.getAvailableGroups(widget.userToken);
      setState(() {
        groups = fetchedGroups;
        isLoading = false;
      });
    } catch (e) {
      setState(() { groups = []; isLoading = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement groupes')),
        );
      }
    }
  }

  Future<void> _joinGroup(int groupId) async {
    try {
      await service.joinGroup(widget.userToken, groupId);
      loadGroups();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur rejoindre groupe')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Rejoindre un groupe")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final g = groups[index];
          return Card(
            margin: EdgeInsets.all(12),
            child: ListTile(
              title: Text(g['nom']),
              subtitle: Text(g['description'] ?? 'Pas de description'),
              trailing: ElevatedButton(
                child: Text("Rejoindre"),
                onPressed: () => _joinGroup(g['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
