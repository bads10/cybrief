import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_bottom_nav_bar.dart';

const String _kBaseUrl = 'https://cybrief-production.up.railway.app';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _articles = [];
  bool _loading = true;
  String _selectedFilter = 'TOUS';

  final List<String> _filters = ['TOUS', 'CRITIQUE', 'ÉLEVÉ', 'MOYEN'];
  final Map<String, Color> _critColors = {
    'CRITIQUE': const Color(0xFFEF4444),
    'ÉLEVÉ': const Color(0xFFF97316),
    'MOYEN': const Color(0xFFFBBF24),
    'FAIBLE': const Color(0xFF22C55E),
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('$_kBaseUrl/api/articles'));
      if (r.statusCode == 200) {
        setState(() { _articles = json.decode(r.body); _loading = false; });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<dynamic> get _filtered => _selectedFilter == 'TOUS'
      ? _articles
      : _articles.where((a) => (a['criticality'] as String? ?? '').toUpperCase() == _selectedFilter).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('INTEL', style: GoogleFonts.inter(
          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1.5,
        )),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec stats rapides
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                _statChip('${_articles.where((a) => (a['criticality'] as String? ?? '').toUpperCase() == 'CRITIQUE').length}', 'CRITIQUES', const Color(0xFFEF4444)),
                const SizedBox(width: 12),
                _statChip('${_articles.where((a) => (a['criticality'] as String? ?? '').toUpperCase() == 'ÉLEVÉ').length}', 'ÉLEVÉS', const Color(0xFFF97316)),
                const SizedBox(width: 12),
                _statChip('${_articles.length}', 'TOTAL', const Color(0xFF38BDF8)),
              ],
            ),
          ),
          // Filtres
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filters.length,
              itemBuilder: (ctx, i) {
                final f = _filters[i];
                final selected = f == _selectedFilter;
                return GestureDetector(
                  onTap: () => setState(() => _selectedFilter = f),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF38BDF8).withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(f, style: GoogleFonts.inter(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: selected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    )),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Liste
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : _filtered.isEmpty
                    ? _emptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _filtered.length,
                        itemBuilder: (ctx, i) => _intelCard(_filtered[i]),
                      ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _statChip(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: color.withValues(alpha: 0.7), letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _intelCard(dynamic article) {
    final crit = article['criticality'] as String? ?? 'MOYEN';
    final color = _critColors[crit] ?? const Color(0xFFFBBF24);
    final cve = (article['cve'] as String? ?? '').trim();
    final attackType = (article['attackType'] as String? ?? '').trim();
    final iocs = (article['iocs'] as String? ?? '').trim();
    final hasIndicators = cve.isNotEmpty || attackType.isNotEmpty || iocs.isNotEmpty;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/threat-detail', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(crit, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                ),
                const Spacer(),
                Icon(LucideIcons.chevronRight, size: 14, color: Colors.white.withValues(alpha: 0.3)),
              ],
            ),
            const SizedBox(height: 8),
            Text(article['title'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white, height: 1.3)),
            if (hasIndicators) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 6, runSpacing: 4, children: [
                if (cve.isNotEmpty) _tag(cve.split(',').first.trim(), const Color(0xFF38BDF8), LucideIcons.shieldAlert),
                if (attackType.isNotEmpty) _tag(attackType, const Color(0xFFA78BFA), LucideIcons.crosshair),
                if (iocs.isNotEmpty) _tag('IOC', const Color(0xFFFBBF24), LucideIcons.activity),
              ]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tag(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 10, color: color),
        const SizedBox(width: 4),
        Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: color)),
      ]),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(LucideIcons.shieldOff, size: 48, color: Colors.white.withValues(alpha: 0.2)),
        const SizedBox(height: 16),
        Text('Aucune menace trouvée', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.4), fontSize: 16)),
      ]),
    );
  }
}
