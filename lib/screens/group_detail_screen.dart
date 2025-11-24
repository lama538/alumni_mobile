import 'package:flutter/material.dart';
import '../services/group_service.dart';

class GroupDetailScreen extends StatefulWidget {
  final String userToken;
  final int groupId;
  final int userId;
  final String groupName;
  final int creatorId;

  const GroupDetailScreen({
    super.key,
    required this.userToken,
    required this.groupId,
    required this.userId,
    required this.groupName,
    required this.creatorId,
  });

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen> {
  late GroupService service;
  List<Map<String, dynamic>> members = [];
  List<Map<String, dynamic>> allUsers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    service = GroupService(baseUrl: 'http://10.0.2.2:8000/api');
    loadMembers();
    if (widget.userId == widget.creatorId) loadAllUsers();
  }

  Future<void> loadMembers() async {
    setState(() => isLoading = true);
    try {
      final fetchedMembers = await service.getGroupMembers(widget.userToken, widget.groupId);
      setState(() {
        members = fetchedMembers;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        members = [];
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Erreur chargement membres'),
              ],
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> loadAllUsers() async {
    try {
      final fetchedUsers = await service.getAllUsers(widget.userToken);

      // *** FILTRE IMPORTANT ***
      // Masquer admin + entreprise
      final filtered = fetchedUsers.where((u) {
        return u['role'] != 'admin' && u['role'] != 'entreprise';
      }).toList();

      setState(() {
        allUsers = filtered;
      });
    } catch (e) {
      setState(() => allUsers = []);
    }
  }


  Future<void> _addMemberDialog() async {
    if (widget.userId != widget.creatorId) return;

    showDialog(
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.person_add_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Ajouter un membre",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: allUsers.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'Aucun utilisateur disponible',
                    style: TextStyle(color: Color(0xFF64748B)),
                  ),
                )
                    : ListView.builder(
                  shrinkWrap: true,
                  itemCount: allUsers.length,
                  itemBuilder: (context, index) {
                    final user = allUsers[index];
                    final isMember = members.any((m) => m['id'] == user['id']);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isMember
                            ? null
                            : () async {
                          await service.addMember(
                            widget.userToken,
                            widget.groupId,
                            user['id'],
                          );
                          Navigator.pop(context);
                          loadMembers();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: isMember ? const Color(0xFFF8FAFC) : Colors.white,
                            border: Border(
                              bottom: BorderSide(
                                color: const Color(0xFFE2E8F0),
                                width: index == allUsers.length - 1 ? 0 : 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: const Color(0xFFEFF6FF),
                                child: Text(
                                  user['name'][0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Color(0xFF3B82F6),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user['name'],
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: isMember
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      user['email'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isMember)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Membre',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.add_circle_rounded,
                                  color: Color(0xFF3B82F6),
                                  size: 24,
                                ),
                            ],
                          ),
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
  }

  Future<void> _removeMember(int userId, String userName) async {
    final canRemove = widget.userId == widget.creatorId || widget.userId == userId;
    if (!canRemove) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(widget.userId == userId ? 'Quitter le groupe ?' : 'Retirer $userName ?'),
        content: Text(
          widget.userId == userId
              ? 'Vous allez quitter ce groupe.'
              : 'Cette personne sera retirée du groupe.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await service.removeMember(widget.userToken, widget.groupId, userId);
      if (widget.userId == userId) {
        if (mounted) Navigator.pop(context);
      } else {
        loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur suppression membre: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCreator = widget.userId == widget.creatorId;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          if (isCreator)
            Container(
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.person_add_rounded, color: Color(0xFF3B82F6)),
                onPressed: _addMemberDialog,
              ),
            ),
        ],
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
          strokeWidth: 3,
        ),
      )
          : members.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people_outline_rounded,
                size: 60,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun membre',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF3B82F6).withOpacity(0.1),
                  const Color(0xFF2563EB).withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF3B82F6).withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.group_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${members.length} membre${members.length > 1 ? 's' : ''} dans ce groupe',
                    style: const TextStyle(
                      color: Color(0xFF1E40AF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: members.length,
              itemBuilder: (context, index) {
                final m = members[index];
                final isMemberCreator = m['id'] == widget.creatorId;
                final isCurrentUser = m['id'] == widget.userId;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: const Color(0xFFEFF6FF),
                          child: Text(
                            m['name'][0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      m['name'],
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  if (isMemberCreator) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF3B82F6),
                                            Color(0xFF2563EB)
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Admin',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (isCurrentUser) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Vous',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                m['email'] ?? '',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isCreator || isCurrentUser)
                          IconButton(
                            icon: Icon(
                              isCurrentUser
                                  ? Icons.exit_to_app_rounded
                                  : Icons.remove_circle_outline_rounded,
                              color: Colors.redAccent,
                            ),
                            onPressed: () => _removeMember(m['id'], m['name']),
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
    );
  }
}