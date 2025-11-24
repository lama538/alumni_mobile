import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/stats_service.dart';
import 'AdminActualitesScreen.dart';
import 'users_list_screen.dart'; // <-- écran pour afficher la liste des utilisateurs

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final StatsService _statsService = StatsService();
  Map<String, dynamic>? stats;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final data = await _statsService.fetchStats();
      setState(() {
        stats = data;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2563EB),
          strokeWidth: 3,
        ),
      )
          : errorMessage != null
          ? Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                errorMessage!,
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadStats,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Réessayer",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadStats,
        color: const Color(0xFF2563EB),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 120,
              floating: false,
              pinned: true,
              elevation: 0,
              backgroundColor: const Color(0xFF2563EB),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Dashboard Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Colors.white),
                  onPressed: _loadStats,
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildEvolutionChart(),
                    const SizedBox(height: 24),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid() {
    final statsData = [
      {
        'icon': Icons.people_rounded,
        'title': 'Alumni',
        'value': stats!['totaux']['alumni'],
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'type': 'alumni',
      },
      {
        'icon': Icons.school_rounded,
        'title': 'Étudiants',
        'value': stats!['totaux']['etudiants'],
        'color': const Color(0xFF0EA5E9),
        'bg': const Color(0xFFE0F2FE),
        'type': 'etudiant',
      },
      {
        'icon': Icons.business_rounded,
        'title': 'Entreprises',
        'value': stats!['totaux']['entreprises'],
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'type': 'entreprise',
      },
      {
        'icon': Icons.work_rounded,
        'title': 'Offres',
        'value': stats!['totaux']['offres'],
        'color': const Color(0xFF06B6D4),
        'bg': const Color(0xFFCFFAFE),
        'type': 'offre',
      },
      {
        'icon': Icons.event_rounded,
        'title': 'Événements',
        'value': stats!['totaux']['evenements'],
        'color': const Color(0xFF6366F1),
        'bg': const Color(0xFFEEF2FF),
      },
      {
        'icon': Icons.group_rounded,
        'title': 'Groupes',
        'value': stats!['totaux']['groupes'],
        'color': const Color(0xFF0284C7),
        'bg': const Color(0xFFE0F2FE),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.15,
      ),
      itemCount: statsData.length,
      itemBuilder: (context, index) {
        final stat = statsData[index];
        return GestureDetector(
          onTap: () {
            if (stat.containsKey('type')) {
              // <-- Correction ici : UsersListScreen (avec s)
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UsersListScreen(type: stat['type'] as String),
                ),
              );
            }
          },
          child: _statCard(
            icon: stat['icon'] as IconData,
            title: stat['title'] as String,
            value: stat['value'],
            color: stat['color'] as Color,
            bgColor: stat['bg'] as Color,
          ),
        );
      },
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required dynamic value,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 26, color: color),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.trending_up_rounded,
                    size: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$value",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEvolutionChart() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Croissance du réseau",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Les 12 derniers mois",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.show_chart_rounded,
                      size: 18,
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      "Analyse",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2563EB),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() % 2 == 0) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              'M${value.toInt() + 1}',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _buildSpots(stats!['evolution']),
                    isCurved: true,
                    curveSmoothness: 0.35,
                    color: const Color(0xFF2563EB),
                    barWidth: 3.5,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 5,
                          color: Colors.white,
                          strokeWidth: 3,
                          strokeColor: const Color(0xFF2563EB),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF2563EB).withOpacity(0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {
        'icon': Icons.work_outline_rounded,
        'label': 'Gérer les offres',
        'color': const Color(0xFF3B82F6),
        'bg': const Color(0xFFEFF6FF),
        'route': '/offres',
      },
      {
        'icon': Icons.event_available_rounded,
        'label': 'Gérer les événements',
        'color': const Color(0xFF8B5CF6),
        'bg': const Color(0xFFF5F3FF),
        'route': '/admin-events',
      },
      {
        'icon': Icons.article_outlined,
        'label': 'Gérer les actualités',
        'color': const Color(0xFF06B6D4),
        'bg': const Color(0xFFCFFAFE),
        'isSpecial': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Actions rapides",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 16),
        ...actions.map((action) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _actionCard(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            color: action['color'] as Color,
            bgColor: action['bg'] as Color,
            onTap: () {
              if (action['isSpecial'] == true) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminActualitesScreen(),
                  ),
                );
              } else {
                Navigator.pushNamed(context, action['route'] as String);
              }
            },
          ),
        )),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.06),
                blurRadius: 15,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<FlSpot> _buildSpots(List<dynamic> evolution) {
    return evolution.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), (e.value['users'] as num).toDouble());
    }).toList();
  }
}
