import 'package:flutter/material.dart';
import '../services/group_service.dart';
import 'group_chat_screen.dart';
import 'GroupCreateScreen.dart';

class GroupListScreen extends StatefulWidget {
  final String userToken;
  final int userId;

  const GroupListScreen({super.key, required this.userToken, required this.userId});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> with SingleTickerProviderStateMixin {
  late GroupService service;
  List<Map<String, dynamic>> myGroups = [];
  List<Map<String, dynamic>> availableGroups = [];
  bool isLoadingMyGroups = true;
  bool isLoadingAvailable = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    service = GroupService(baseUrl: 'http://10.0.2.2:8000/api');
    _tabController = TabController(length: 2, vsync: this);
    loadMyGroups();
    loadAvailableGroups();
  }

  Future<void> loadMyGroups() async {
    setState(() => isLoadingMyGroups = true);
    try {
      final fetchedGroups = await service.getUserGroups(widget.userToken);
      setState(() {
        myGroups = fetchedGroups;
      });
    } catch (e) {
      myGroups = [];
    } finally {
      if (mounted) setState(() => isLoadingMyGroups = false);
    }
  }

  Future<void> loadAvailableGroups() async {
    setState(() => isLoadingAvailable = true);
    try {
      final fetchedGroups = await service.getAvailableGroups(widget.userToken);
      setState(() {
        availableGroups = fetchedGroups;
      });
    } catch (e) {
      availableGroups = [];
    } finally {
      if (mounted) setState(() => isLoadingAvailable = false);
    }
  }

  Future<void> _createGroup() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GroupCreateScreen(userToken: widget.userToken),
      ),
    );
    if (result == true) {
      loadMyGroups();
      loadAvailableGroups();
    }
  }

  Future<void> _deleteGroup(int id) async {
    try {
      await service.deleteGroup(widget.userToken, id);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Groupe supprimé avec succès !"),
          backgroundColor: Colors.green,
        ),
      );

      loadMyGroups();
      loadAvailableGroups();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll("Exception: ", "")),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Column(
        children: [
          Container(
            height: 140,
            child: AppBar(
              title: const Text(
                'Mes Groupes',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              backgroundColor: Colors.white,
              elevation: 0,
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add_rounded, color: Colors.white),
                    onPressed: _createGroup,
                  ),
                ),
              ],
              bottom: TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF3B82F6),
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Mes Groupes'),
                  Tab(text: 'Groupes disponibles'),
                ],
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGroupList(myGroups, isLoadingMyGroups),
                _buildGroupList(availableGroups, isLoadingAvailable, joinable: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupList(List<Map<String, dynamic>> groups, bool isLoading, {bool joinable = false}) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (groups.isEmpty) {
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
              child: const Icon(Icons.group_outlined, size: 80, color: Color(0xFF3B82F6)),
            ),
            const SizedBox(height: 24),
            Text(
              joinable ? "Aucun groupe disponible" : "Aucun groupe",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final g = groups[index];
        final isCreator = g['creator_id'] == widget.userId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: joinable
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GroupChatScreen(
                      userToken: widget.userToken,
                      userId: widget.userId,
                      groupId: g['id'],
                      groupName: g['nom'],
                      creatorId: g['creator_id'],
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // === Icône groupe ===
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF3B82F6).withOpacity(0.1),
                            const Color(0xFF2563EB).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.group_rounded, color: Color(0xFF3B82F6), size: 32),
                    ),

                    const SizedBox(width: 16),

                    // === Informations groupe ===
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  g['nom'],
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                              ),

                              // === Badges Admin ===
                              if (isCreator && !joinable)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                        colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Admin',
                                    style: TextStyle(fontSize: 11, color: Colors.white),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 6),

                          Text(
                            g['description'] ?? 'Pas de description',
                            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 12),

                    // ===== Icône Chat (Mes groupes) =====
                    if (!joinable)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.chat_bubble_rounded, size: 20, color: Color(0xFF3B82F6)),
                      ),

                    // ===== Bouton SUPPRIMER (créateur uniquement) =====
                    if (!joinable && isCreator)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text("Supprimer le groupe ?"),
                              content: const Text("Voulez-vous vraiment supprimer ce groupe ?"),
                              actions: [
                                TextButton(
                                  child: const Text("Annuler"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                                TextButton(
                                  child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteGroup(g['id']);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    // ===== Bouton REJOINDRE (Groupes disponibles) =====
                    if (joinable)
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await service.joinGroup(widget.userToken, g['id']);
                            loadMyGroups();
                            loadAvailableGroups();
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(e.toString().replaceAll("Exception: ", "")),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }

                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6)),
                        child: const Text('Rejoindre'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
