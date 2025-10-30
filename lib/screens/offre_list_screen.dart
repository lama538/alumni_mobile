import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offre_model.dart';
import '../services/offre_service.dart';
import 'offre_detail_screen.dart';
import 'offre_form_screen.dart';

class OffreListScreen extends StatefulWidget {
  const OffreListScreen({super.key});

  @override
  State<OffreListScreen> createState() => _OffreListScreenState();
}

class _OffreListScreenState extends State<OffreListScreen> {
  String token = '';
  String role = '';
  List<Offre> offres = [];
  List<Offre> filtered = [];
  bool isLoading = false;

  String selectedType = 'all';
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAuth();
  }

  void _loadAuth() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('token') ?? '';
      role = prefs.getString('role') ?? '';
    });
    fetchOffres();
  }

  void fetchOffres() async {
    setState(() => isLoading = true);
    try {
      final data = await OffreService.getAll(token);
      setState(() {
        offres = data;
        applyFilters();
      });
    } catch (e) {
      debugPrint('Erreur fetch offres: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Erreur de chargement des offres'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  void applyFilters() {
    final search = searchController.text.toLowerCase();
    setState(() {
      filtered = offres.where((o) {
        final matchesSearch = o.titre.toLowerCase().contains(search) ||
            o.description.toLowerCase().contains(search) ||
            (o.userName ?? '').toLowerCase().contains(search);
        final matchesType = selectedType == 'all' || o.type == selectedType;
        return matchesSearch && matchesType;
      }).toList();
    });
  }

  void onSearch(String q) {
    applyFilters();
  }

  void onTypeChanged(String? t) {
    setState(() {
      selectedType = t ?? 'all';
    });
    applyFilters();
  }

  void openForm([Offre? existing]) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OffreFormScreen(token: token, existing: existing),
      ),
    );
    if (changed == true) fetchOffres();
  }

  void openDetail(Offre o) async {
    final changed = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OffreDetailScreen(token: token, offre: o),
      ),
    );
    if (changed == true) fetchOffres();
  }

  @override
  Widget build(BuildContext context) {
    final canPublish = role == 'alumni' || role == 'entreprise' || role == 'admin';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: const Color(0xFF2563EB),
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Offres d\'emploi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              centerTitle: true,
              background: Container(color: const Color(0xFF2563EB)),
            ),
            actions: [
              if (canPublish)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white),
                    ),
                    tooltip: 'Publier une offre',
                    onPressed: () => openForm(),
                  ),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildSearchAndFilters(),
                const SizedBox(height: 16),
              ],
            ),
          ),
          isLoading
              ? const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                strokeWidth: 3,
              ),
            ),
          )
              : filtered.isEmpty
              ? SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.work_outline_rounded,
                      size: 64,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Aucune offre disponible',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    selectedType != 'all'
                        ? 'Essayez de changer le filtre'
                        : 'Revenez plus tard',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          )
              : SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  final o = filtered[index];
                  return _buildOffreCard(o);
                },
                childCount: filtered.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
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
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Rechercher une offre...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF2563EB),
                  size: 24,
                ),
                suffixIcon: searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear_rounded, color: Color(0xFF94A3B8)),
                  onPressed: () {
                    searchController.clear();
                    onSearch('');
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
              onChanged: onSearch,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFilterChip('Tous', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Emploi', 'emploi'),
              const SizedBox(width: 8),
              _buildFilterChip('Stage', 'stage'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = selectedType == value;
    return Expanded(
      child: InkWell(
        onTap: () => onTypeChanged(value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF2563EB) : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF64748B),
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOffreCard(Offre o) {
    final isEmploi = o.type == 'emploi';
    final typeColor = isEmploi ? const Color(0xFF3B82F6) : const Color(0xFF8B5CF6);
    final typeBg = isEmploi ? const Color(0xFFEFF6FF) : const Color(0xFFF5F3FF);

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => openDetail(o),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: typeBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isEmploi ? Icons.work_rounded : Icons.school_rounded,
                            size: 16,
                            color: typeColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            o.type.toUpperCase(),
                            style: TextStyle(
                              color: typeColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: const Color(0xFF94A3B8),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  o.titre,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  o.description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (o.userName != null && o.userName!.isNotEmpty) ...[
                      const Icon(
                        Icons.person_outline_rounded,
                        size: 16,
                        color: Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          o.userName!,
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
                    if (o.dateExpiration != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule_rounded,
                        size: 16,
                        color: Colors.orange[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Expire le ${o.dateExpiration!.toLocal().toString().split(' ')[0]}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}