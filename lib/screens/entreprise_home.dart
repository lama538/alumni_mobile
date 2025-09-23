import 'package:flutter/material.dart';

class EntrepriseHome extends StatelessWidget {
  const EntrepriseHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Accueil Entreprise")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _homeCard(Icons.post_add, "Publier une Offre", Colors.blue, () {}),
          _homeCard(Icons.group, "Candidatures", Colors.green, () {}),
          _homeCard(Icons.message, "Messages", Colors.orange, () {}),
        ],
      ),
    );
  }

  Widget _homeCard(IconData icon, String title, Color color, VoidCallback onTap) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
