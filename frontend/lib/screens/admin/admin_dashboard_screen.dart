import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/api_service.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      _stats = await ApiService().getStats();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Color _langColor(String lang) {
    switch (lang) {
      case 'UZ': return const Color(0xFF00C9A7);
      case 'RU': return const Color(0xFF4FC3F7);
      case 'EN': return const Color(0xFF6C63FF);
      case 'QQ': return const Color(0xFFFF8E53);
      default:    return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : _stats == null
              ? const Center(child: Text('Ma\'lumot kelmadi', style: TextStyle(color: Colors.white38)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF6C63FF),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stat kartochkalari
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.people_outline_rounded,
                                label: 'Foydalanuvchilar',
                                value: '${_stats!['total_users'] ?? 0}',
                                color: const Color(0xFF6C63FF),
                              ).animate().fadeIn(delay: 50.ms).scale(begin: const Offset(0.9, 0.9)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.analytics_outlined,
                                label: 'Tahlillar',
                                value: '${_stats!['total_analyses'] ?? 0}',
                                color: const Color(0xFF00C9A7),
                              ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.9, 0.9)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Til taqsimoti Pie chart
                        const Text('Tillar taqsimoti',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Container(
                          height: 220,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.04),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: _buildPieChart(),
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 24),

                        // Kunlik tahlillar
                        const Text('Kunlik tahlillar (so\'nggi 7 kun)',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        Container(
                          height: 180,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white.withOpacity(0.04),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: _buildBarChart(),
                        ).animate().fadeIn(delay: 300.ms),

                        const SizedBox(height: 24),

                        // So'nggi foydalanuvchilar
                        const Text('So\'nggi foydalanuvchilar',
                            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 12),
                        ..._buildRecentUsers(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildPieChart() {
    final langDist = Map<String, int>.from(_stats!['lang_distribution'] ?? {});
    if (langDist.isEmpty) {
      return const Center(child: Text('Ma\'lumot yo\'q', style: TextStyle(color: Colors.white38)));
    }
    final total = langDist.values.fold(0, (a, b) => a + b);
    final sections = langDist.entries.map((e) {
      final pct = e.value / total;
      return PieChartSectionData(
        value: e.value.toDouble(),
        title: '${e.key}\n${(pct * 100).round()}%',
        color: _langColor(e.key),
        radius: 60,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return PieChart(PieChartData(
      sections: sections,
      sectionsSpace: 3,
      centerSpaceRadius: 30,
    ));
  }

  Widget _buildBarChart() {
    final daily = (_stats!['daily_analyses'] as List?) ?? [];
    if (daily.isEmpty) {
      return const Center(child: Text('Ma\'lumot yo\'q', style: TextStyle(color: Colors.white38)));
    }
    final reversed = daily.reversed.toList();
    final maxVal = reversed.map((e) => (e['count'] as int)).fold(0, (a, b) => a > b ? a : b);

    return BarChart(BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxVal.toDouble() + 1,
      barGroups: reversed.asMap().entries.map((entry) {
        final count = (entry.value['count'] as int).toDouble();
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: count,
              color: const Color(0xFF6C63FF),
              width: 18,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (v, _) {
              final idx = v.toInt();
              if (idx < 0 || idx >= reversed.length) return const SizedBox();
              final date = reversed[idx]['date'] as String;
              final parts = date.split('-');
              return Text('${parts[2]}/${parts[1]}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10));
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withOpacity(0.05)),
      ),
      borderData: FlBorderData(show: false),
    ));
  }

  List<Widget> _buildRecentUsers() {
    final users = (_stats!['recent_users'] as List?) ?? [];
    return users.asMap().entries.map((entry) {
      final u = entry.value as Map;
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withOpacity(0.04),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D5AFE)]),
              ),
              child: Center(
                child: Text(
                  (u['full_name'] as String).isNotEmpty ? u['full_name'][0].toUpperCase() : 'U',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(u['full_name'] ?? '', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                Text(u['email'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              ]),
            ),
            if (u['role'] == 'admin')
              const Icon(Icons.admin_panel_settings, color: Color(0xFFFF8E53), size: 16),
          ],
        ),
      ).animate(delay: (entry.key * 50).ms).fadeIn().slideX(begin: 0.05);
    }).toList();
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _StatCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 12),
        Text(value, style: TextStyle(color: color, fontSize: 28, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ]),
    );
  }
}
