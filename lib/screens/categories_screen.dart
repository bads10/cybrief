import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/terminal_widgets.dart';
import '../theme/terminal_theme.dart';
import '../services/api_constants.dart';
import 'article_browser_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<dynamic> _articles = [];
  bool _loading = true;
  String _selectedFilter = 'TOUS';

  static const _filters = ['TOUS', 'CRITIQUE', 'ÉLEVÉ', 'MOYEN', 'FAIBLE'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r = await http
          .get(Uri.parse('$kApiBaseUrl/api/articles'))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) {
        final body = json.decode(r.body);
        setState(() {
          _articles = body is List ? body : (body['articles'] as List? ?? []);
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _critToV1(String crit) {
    final c = crit.toUpperCase();
    if (c.contains('CRIT')) return 'CRIT';
    if (c.contains('ELEV') || c.contains('HIGH')) return 'HIGH';
    if (c.contains('MOY') || c.contains('MED')) return 'MED';
    if (c.contains('FAI') || c.contains('LOW')) return 'LOW';
    return 'MED';
  }

  List<dynamic> get _filtered {
    if (_selectedFilter == 'TOUS') return _articles;
    return _articles.where((a) {
      final c = (a['criticality'] as String? ?? '').toUpperCase();
      return c == _selectedFilter ||
          (c.contains('CRIT') && _selectedFilter == 'CRITIQUE') ||
          (c.contains('ELEV') && _selectedFilter == 'ÉLEVÉ') ||
          (c.contains('MOY') && _selectedFilter == 'MOYEN') ||
          (c.contains('FAI') && _selectedFilter == 'FAIBLE');
    }).toList();
  }

  int _countBy(String filter) {
    if (filter == 'TOUS') return _articles.length;
    return _articles.where((a) {
      final c = (a['criticality'] as String? ?? '').toUpperCase();
      return c == filter ||
          (c.contains('CRIT') && filter == 'CRITIQUE') ||
          (c.contains('ELEV') && filter == 'ÉLEVÉ') ||
          (c.contains('MOY') && filter == 'MOYEN') ||
          (c.contains('FAI') && filter == 'FAIBLE');
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          TerminalTopBar(
            label: 'INTEL // CVE+IOC',
            right: '${_articles.length} / TOTAL',
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 4 severity count cards
                _buildCountGrid(),

                // Search + sort bar
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(12, 10, 12, 0),
                  child: Row(children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: TT.surface,
                          border: Border.all(color: TT.line, width: 1),
                        ),
                        child: Text('\$ filter criticité...',
                            style: TT.mono(
                                size: 11, color: TT.muted)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border:
                              Border.all(color: TT.line, width: 1),
                        ),
                        child: Text('SORT ▼',
                            style: TT.mono(
                                size: 11, color: TT.text)),
                      ),
                    ),
                  ]),
                ),

                // Filter chips
                SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                    itemCount: _filters.length,
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final sel = f == _selectedFilter;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedFilter = f),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: sel ? TT.accent : TT.line,
                              width: 1,
                            ),
                            color: sel
                                ? TT.accent.withOpacity(0.12)
                                : Colors.transparent,
                          ),
                          child: Text(f,
                              style: TT.mono(
                                  size: 10,
                                  color: sel ? TT.accent : TT.muted,
                                  letterSpacing: 0.5)),
                        ),
                      );
                    },
                  ),
                ),

                // Table header
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  decoration: const BoxDecoration(
                    color: TT.surface,
                    border: Border(
                      top: BorderSide(color: TT.line),
                      bottom: BorderSide(color: TT.line),
                    ),
                  ),
                  padding:
                      const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(children: [
                    SizedBox(
                        width: 54,
                        child: Text('SEV',
                            style: TT.mono(size: 9, letterSpacing: 0.6))),
                    Expanded(
                        child: Text('ID / TITRE',
                            style: TT.mono(
                                size: 9, letterSpacing: 0.6))),
                    SizedBox(
                        width: 50,
                        child: Text('CVSS',
                            textAlign: TextAlign.right,
                            style: TT.mono(
                                size: 9, letterSpacing: 0.6))),
                    SizedBox(
                        width: 46,
                        child: Text('DATE',
                            textAlign: TextAlign.right,
                            style: TT.mono(
                                size: 9, letterSpacing: 0.6))),
                  ]),
                ),

                // Article list
                Expanded(
                  child: _loading
                      ? const Center(
                          child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: TT.accent, strokeWidth: 1.5)))
                      : _filtered.isEmpty
                          ? Center(
                              child: Text('Aucune menace trouvée',
                                  style: TT.mono(
                                      size: 12, color: TT.muted)))
                          : RefreshIndicator(
                              onRefresh: _load,
                              color: TT.accent,
                              backgroundColor: TT.surface,
                              child: ListView.builder(
                                physics:
                                    const AlwaysScrollableScrollPhysics(),
                                itemCount: _filtered.length,
                                itemBuilder: (_, i) =>
                                    _buildRow(_filtered[i]),
                              ),
                            ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildCountGrid() {
    final crit  = _countBy('CRITIQUE');
    final high  = _countBy('ÉLEVÉ');
    final med   = _countBy('MOYEN');
    final low   = _countBy('FAIBLE');

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: TT.line, width: 1)),
      ),
      child: Row(children: [
        _countCard('CRIT', crit, TT.red),
        _countCard('HIGH', high, TT.orange),
        _countCard('MED', med, TT.yellow),
        _countCard('LOW', low, TT.green, last: true),
      ]),
    );
  }

  Widget _countCard(String label, int count, Color color,
      {bool last = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          border: Border(
            right: last
                ? BorderSide.none
                : const BorderSide(color: TT.line, width: 1),
          ),
        ),
        child: Column(children: [
          Text('$count',
              style: TT.sans(
                  size: 22,
                  weight: FontWeight.w800,
                  color: color,
                  letterSpacing: -1)),
          const SizedBox(height: 2),
          Text(label,
              style: TT.mono(
                  size: 9,
                  weight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1)),
        ]),
      ),
    );
  }

  Widget _buildRow(dynamic article) {
    final critRaw = (article['criticality'] as String? ?? 'MOYEN');
    final level   = _critToV1(critRaw);
    final cve     = (article['cve'] as String? ?? '').trim();
    final title   = (article['title'] as String? ?? '');
    final date    = _formatDate(article['createdAt'] as String?);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArticleBrowserScreen(
            url: (article['url'] as String? ?? ''),
            title: title,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TT.line, width: 1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(width: 54, child: TerminalSevTag(level: level)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cve.isNotEmpty)
                    Text(cve.split(',').first.trim(),
                        style: TT.mono(
                            size: 10, color: TT.accent, letterSpacing: 0.4)),
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TT.sans(
                          size: 12,
                          weight: FontWeight.w600,
                          color: TT.text,
                          height: 1.3)),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 50,
              child: Text('—',
                  textAlign: TextAlign.right,
                  style: TT.mono(
                      size: 12, weight: FontWeight.w700, color: TT.text)),
            ),
            SizedBox(
              width: 46,
              child: Text(date,
                  textAlign: TextAlign.right,
                  style: TT.mono(size: 10, color: TT.muted)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String? isoDate) {
    if (isoDate == null) return '—';
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
    } catch (_) {
      return '—';
    }
  }
}
