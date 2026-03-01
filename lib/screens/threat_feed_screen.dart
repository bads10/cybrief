import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/custom_bottom_nav_bar.dart';

// URL du backend — localhost fonctionne dans le simulateur iOS
const String _kBaseUrl = 'http://localhost:3000';

class Article {
  final int id;
  final String title;
  final String summary;
  final String criticality;
  final String tags;
  final String url;
  final DateTime createdAt;
  // Indicateurs techniques
  final String cve;
  final String attackType;
  final String affectedSystems;
  final String iocs;

  const Article({
    required this.id,
    required this.title,
    required this.summary,
    required this.criticality,
    required this.tags,
    required this.url,
    required this.createdAt,
    this.cve = '',
    this.attackType = '',
    this.affectedSystems = '',
    this.iocs = '',
  });

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      title: json['title'] as String? ?? '—',
      summary: json['summary'] as String? ?? '',
      criticality: json['criticality'] as String? ?? 'Info',
      tags: json['tags'] as String? ?? '',
      url: json['url'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      cve: json['cve'] as String? ?? '',
      attackType: json['attackType'] as String? ?? '',
      affectedSystems: json['affectedSystems'] as String? ?? '',
      iocs: json['iocs'] as String? ?? '',
    );
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays}j';
  }

  bool get isUrgent => criticality == 'Critique' || criticality == 'Critical';
}

class ThreatFeedScreen extends StatefulWidget {
  const ThreatFeedScreen({super.key});

  @override
  State<ThreatFeedScreen> createState() => _ThreatFeedScreenState();
}

class _ThreatFeedScreenState extends State<ThreatFeedScreen> {
  List<Article> _articles = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchArticles();
  }

  Future<void> _fetchArticles() async {
    setState(() { _loading = true; _error = null; });
    try {
      final response = await http
          .get(Uri.parse('$_kBaseUrl/api/articles'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        setState(() {
          _articles = data
              .map((e) => Article.fromJson(e as Map<String, dynamic>))
              .toList();
          _loading = false;
        });
      } else {
        setState(() { _error = 'Erreur serveur (${response.statusCode})'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Impossible de joindre le serveur'; _loading = false; });
    }
  }

  String _todayLabel() {
    const jours = ['LUNDI', 'MARDI', 'MERCREDI', 'JEUDI', 'VENDREDI', 'SAMEDI', 'DIMANCHE'];
    const mois = [
      'JANVIER', 'FÉVRIER', 'MARS', 'AVRIL', 'MAI', 'JUIN',
      'JUILLET', 'AOÛT', 'SEPTEMBRE', 'OCTOBRE', 'NOVEMBRE', 'DÉCEMBRE'
    ];
    final now = DateTime.now();
    return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        centerTitle: false,
        title: Text(
          'Cybrief',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bell, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(LucideIcons.user, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchArticles,
        color: const Color(0xFF38BDF8),
        backgroundColor: const Color(0xFF1E293B),
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  Text(
                    _todayLabel(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF38BDF8),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Le Brief Cyber',
                    style: GoogleFonts.inter(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "L'essentiel de la menace en 2 minutes.",
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: Color(0xFF38BDF8)),
                ),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.wifiOff, color: Colors.white38, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextButton.icon(
                        onPressed: _fetchArticles,
                        icon: const Icon(LucideIcons.refreshCw, size: 16),
                        label: const Text('Réessayer'),
                        style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
                      ),
                    ],
                  ),
                ),
              )
            else if (_articles.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.shieldOff, color: Colors.white24, size: 40),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune alerte pour le moment.',
                        style: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index == _articles.length) return const SizedBox(height: 24);
                      return _buildThreatItem(context, _articles[index]);
                    },
                    childCount: _articles.length + 1,
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildThreatItem(BuildContext context, Article article) {
    Color severityColor;
    switch (article.criticality) {
      case 'Critique':
      case 'Critical':
        severityColor = Colors.redAccent;
        break;
      case 'Élevé':
      case 'High':
        severityColor = Colors.orangeAccent;
        break;
      case 'Moyen':
      case 'Medium':
        severityColor = Colors.yellowAccent;
        break;
      default:
        severityColor = Colors.blueAccent;
    }

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/detail', arguments: article),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: article.isUrgent
                ? Colors.redAccent.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.05),
          ),
          boxShadow: article.isUrgent
              ? [
                  BoxShadow(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    article.criticality,
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  article.timeAgo,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              article.title,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                height: 1.3,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              article.summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.white.withValues(alpha: 0.6),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Lire la suite',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  LucideIcons.arrowRight,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
