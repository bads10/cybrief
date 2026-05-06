import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/brief_item.dart';
import '../widgets/brief_card.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';
import '../services/api_constants.dart';

class FluxScreen extends StatefulWidget {
  const FluxScreen({super.key});

  @override
  State<FluxScreen> createState() => _FluxScreenState();
}

class _FluxScreenState extends State<FluxScreen> {
  static const String _kBaseUrl = kApiBaseUrl;

  List<BriefItem> _items = [];
  bool _isLoading = true;
  bool _isPremium = false;
  bool _quotaReached = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Sync user backend + vérifier premium en parallèle
      await Future.wait([
        UserService.syncUser(uid: user.uid, email: user.email ?? '', displayName: user.displayName),
        _checkPremium(user.uid),
      ]);
    }
    await _fetchBriefs();
  }

  Future<void> _checkPremium(String uid) async {
    final premium = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Future<void> _fetchBriefs() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final uri = Uri.parse('$_kBaseUrl/api/articles').replace(
        queryParameters: uid != null ? {'userId': uid} : null,
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        // Nouveau format : { articles: [], quotaReached: bool }
        List<dynamic> data;
        bool quotaReached = false;

        if (body is Map) {
          data = (body['articles'] as List?) ?? [];
          quotaReached = body['quotaReached'] as bool? ?? false;
        } else {
          // Compatibilité ancien format liste directe
          data = body as List<dynamic>;
        }

        setState(() {
          _items = data.map((e) => BriefItem.fromJson(e as Map<String, dynamic>)).toList();
          _quotaReached = quotaReached;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Erreur serveur (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Impossible de joindre le serveur. Vérifiez votre connexion.';
        _isLoading = false;
      });
    }
  }

  String _getFormattedDate() {
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text('Cybrief', style: AppTextStyles.headline.copyWith(fontSize: 20, letterSpacing: -0.5)),
        actions: [
          if (_isPremium)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
            ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: AppColors.textSecondary),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchBriefs,
        color: AppColors.cyan,
        backgroundColor: AppColors.surfaceElevated,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getFormattedDate(), style: AppTextStyles.label.copyWith(
                      color: AppColors.cyan, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 8),
                    Text('Le Brief Cyber', style: AppTextStyles.headline.copyWith(fontSize: 32, height: 1.1)),
                    const SizedBox(height: 8),
                    Text("L'essentiel de la menace en 2 minutes.", style: AppTextStyles.body.copyWith(
                      fontSize: 16, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ),

            // States
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: AppColors.cyan)),
              )
            else if (_error != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!, textAlign: TextAlign.center, style: AppTextStyles.body),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchBriefs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyanSurface,
                            foregroundColor: AppColors.cyan,
                          ),
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty && !_quotaReached)
              const SliverFillRemaining(
                child: Center(child: Text('Aucun brief pour le moment.', style: AppTextStyles.body)),
              )
            else ...[
              // Liste des articles
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => BriefCard(
                    brief: _items[index],
                    isUserPremium: _isPremium,
                    onSubscribeTap: () => Navigator.pushNamed(context, '/subscribe'),
                  ),
                  childCount: _items.length,
                ),
              ),

              // Paywall interstitiel si quota atteint
              if (_quotaReached && !_isPremium)
                SliverToBoxAdapter(child: _buildPaywallBanner()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildPaywallBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E1040), Color(0xFF0D1F3C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.lock_outline_rounded, color: Color(0xFF38BDF8), size: 32),
            const SizedBox(height: 12),
            Text(
              'Tu as lu tes 5 briefs du jour',
              textAlign: TextAlign.center,
              style: AppTextStyles.headline.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              'Passe à Premium pour un accès illimité,\nles CVE complets et les alertes temps réel.',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF135BEC), Color(0xFF38BDF8)]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/subscribe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Commencer l\'essai 7 jours gratuits',
                    style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text('9,99€/mois · 79,99€/an · Sans engagement',
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
