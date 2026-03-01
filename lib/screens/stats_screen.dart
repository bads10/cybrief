import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_bottom_nav_bar.dart';

const String _kBaseUrl = 'https://cybrief-production.up.railway.app';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await http.get(Uri.parse('$_kBaseUrl/api/stats'));
      if (r.statusCode == 200) {
        setState(() { _stats = json.decode(r.body); _loading = false; });
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('STATS', style: GoogleFonts.inter(
          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1.5,
        )),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, color: Colors.white54, size: 18),
            onPressed: () { setState(() => _loading = true); _load(); },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _stats == null
              ? _errorState()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF38BDF8),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeroCard(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Répartition par criticité'),
                        const SizedBox(height: 14),
                        _buildCriticalityBars(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Top menaces actives'),
                        const SizedBox(height: 14),
                        _buildTopAttacks(),
                        const SizedBox(height: 24),
                        _buildSectionTitle('Tags les plus fréquents'),
                        const SizedBox(height: 14),
                        _buildTopTags(),
                        if ((_stats!['cves'] as List).isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _buildSectionTitle('CVEs récents'),
                          const SizedBox(height: 14),
                          _buildCveList(),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildHeroCard() {
    final total = _stats!['total'] as int? ?? 0;
    final last24h = _stats!['last24h'] as int? ?? 0;
    final critique = _stats!['critique'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF135BEC), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Articles publiés', style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.85), fontSize: 13, fontWeight: FontWeight.w500,
              )),
              const Icon(LucideIcons.barChart2, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 10),
          Text('$total', style: GoogleFonts.libreBaskerville(
            color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold,
          )),
          const SizedBox(height: 8),
          Row(children: [
            _heroBadge('$last24h dernières 24h', Colors.white.withValues(alpha: 0.2)),
            const SizedBox(width: 8),
            if (critique > 0) _heroBadge('$critique critiques', const Color(0xFFEF4444).withValues(alpha: 0.4)),
          ]),
        ],
      ),
    );
  }

  Widget _heroBadge(String text, Color bg) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(text, style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _buildSectionTitle(String title) => Text(title, style: GoogleFonts.inter(
    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
  ));

  Widget _buildCriticalityBars() {
    final total = (_stats!['total'] as int? ?? 1).clamp(1, 9999);
    final items = [
      {'label': 'CRITIQUE', 'count': _stats!['critique'] as int? ?? 0, 'color': const Color(0xFFEF4444)},
      {'label': 'ÉLEVÉ',    'count': _stats!['eleve']    as int? ?? 0, 'color': const Color(0xFFF97316)},
      {'label': 'MOYEN',    'count': _stats!['moyen']    as int? ?? 0, 'color': const Color(0xFFFBBF24)},
      {'label': 'FAIBLE',   'count': _stats!['faible']   as int? ?? 0, 'color': const Color(0xFF22C55E)},
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        children: items.map((item) {
          final count = item['count'] as int;
          final color = item['color'] as Color;
          final pct = count / total;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              children: [
                Row(children: [
                  Text(item['label'] as String, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                  const Spacer(),
                  Text('$count', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopAttacks() {
    final attacks = (_stats!['topAttacks'] as List? ?? []);
    if (attacks.isEmpty) return _emptyChip('Aucun type d\'attaque détecté');
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: attacks.map((a) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFA78BFA).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFA78BFA).withValues(alpha: 0.25)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(LucideIcons.crosshair, size: 12, color: Color(0xFFA78BFA)),
          const SizedBox(width: 6),
          Text('${a['type']}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFFA78BFA))),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(color: const Color(0xFFA78BFA).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10)),
            child: Text('${a['count']}', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFFA78BFA))),
          ),
        ]),
      )).toList(),
    );
  }

  Widget _buildTopTags() {
    final tags = (_stats!['topTags'] as List? ?? []);
    if (tags.isEmpty) return _emptyChip('Aucun tag');
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: tags.map((t) {
        final count = t['count'] as int? ?? 0;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
          ),
          child: Text('${t['tag']}  $count', style: GoogleFonts.inter(
            fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF38BDF8),
          )),
        );
      }).toList(),
    );
  }

  Widget _buildCveList() {
    final cves = (_stats!['cves'] as List? ?? []);
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: cves.map((cve) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
        ),
        child: Text('$cve', style: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444),
        )),
      )).toList(),
    );
  }

  Widget _emptyChip(String text) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(text, style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3), fontSize: 13)),
  );

  Widget _errorState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(LucideIcons.wifiOff, size: 48, color: Colors.white.withValues(alpha: 0.2)),
      const SizedBox(height: 16),
      Text('Impossible de charger les stats', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.4))),
      const SizedBox(height: 16),
      TextButton(onPressed: () { setState(() => _loading = true); _load(); },
        child: const Text('Réessayer', style: TextStyle(color: Color(0xFF38BDF8)))),
    ]),
  );
}
