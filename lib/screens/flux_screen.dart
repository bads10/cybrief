import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../models/brief_item.dart';
import '../widgets/brief_card.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/terminal_widgets.dart';
import '../theme/terminal_theme.dart';
import '../services/user_service.dart';
import '../services/subscription_service.dart';
import '../services/api_constants.dart';

class FluxScreen extends StatefulWidget {
  const FluxScreen({super.key});

  @override
  State<FluxScreen> createState() => _FluxScreenState();
}

class _FluxScreenState extends State<FluxScreen> {
  static const int _pageSize = 20;
  static const Duration _autoRefreshInterval = Duration(minutes: 5);

  final ScrollController _scrollCtrl = ScrollController();

  List<BriefItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isPremium = false;
  bool _quotaReached = false;
  String? _error;
  String? _nextCursor;
  bool _hasMore = true;
  String _lang = 'fr';

  // Auto-refresh
  Timer? _autoRefreshTimer;
  int _newArticlesCount = 0;
  DateTime? _lastRefreshTime;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(_autoRefreshInterval, (_) {
      _checkNewArticles();
    });
  }

  /// Vérifie silencieusement si de nouveaux articles sont disponibles
  Future<void> _checkNewArticles() async {
    if (_items.isEmpty || _lastRefreshTime == null) return;
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final params = <String, String>{'limit': '5', 'lang': _lang};
      if (uid != null) params['userId'] = uid;
      final uri = Uri.parse('$kApiBaseUrl/api/articles')
          .replace(queryParameters: params);
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (!mounted || response.statusCode != 200) return;

      final body = jsonDecode(response.body);
      final List data = body is List ? body : (body['articles'] as List? ?? []);
      if (data.isEmpty) return;

      final latestId = data.first['id']?.toString() ?? '';
      if (latestId.isNotEmpty && latestId != _items.first.id) {
        // Compter les vraiment nouveaux
        final existingIds = _items.map((e) => e.id).toSet();
        final newCount = data
            .where((e) => !existingIds.contains(e['id']?.toString()))
            .length;
        if (newCount > 0 && mounted) {
          setState(() => _newArticlesCount = newCount);
        }
      }
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_quotaReached) {
      _loadMore();
    }
  }

  Future<void> _init() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await Future.wait([
        UserService.syncUser(
            uid: user.uid,
            email: user.email ?? '',
            displayName: user.displayName),
        _checkPremium(),
      ]);
      // Sauvegarder le token FCM après que l'user existe en DB
      _saveFcmToken(user.uid);
    }
    await _fetchBriefs();
  }

  Future<void> _saveFcmToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await UserService.updateUser(uid, {'fcmToken': token});
      }
    } catch (_) {}
  }

  Future<void> _checkPremium() async {
    final premium = await SubscriptionService.isPremium();
    if (mounted) setState(() => _isPremium = premium);
  }

  Uri _buildUri({String? cursor}) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final params = <String, String>{'limit': '$_pageSize'};
    if (uid != null) params['userId'] = uid;
    if (cursor != null) params['cursor'] = cursor;
    return Uri.parse('$kApiBaseUrl/api/articles')
        .replace(queryParameters: params);
  }

  Future<void> _fetchBriefs() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _nextCursor = null;
      _hasMore = true;
      _newArticlesCount = 0;
    });
    try {
      final response =
          await http.get(_buildUri()).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data;
        String? nextCursor;
        bool quotaReached = false;
        if (body is List) {
          data = body;
        } else {
          data = (body['articles'] as List?) ?? [];
          nextCursor = body['nextCursor'] as String?;
          quotaReached = body['quotaReached'] as bool? ?? false;
        }
        setState(() {
          _items = data
              .map((e) => BriefItem.fromJson(e as Map<String, dynamic>, lang: _lang))
              .toList();
          _quotaReached = quotaReached;
          _nextCursor = nextCursor;
          _hasMore = nextCursor != null;
          _isLoading = false;
          _lastRefreshTime = DateTime.now();
        });
      } else {
        setState(() {
          _error = 'Erreur serveur (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'error'; _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await http
          .get(_buildUri(cursor: _nextCursor))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data =
            body is List ? body : (body['articles'] as List? ?? []);
        final String? nextCursor =
            body is Map ? body['nextCursor'] as String? : null;
        setState(() {
          _items.addAll(
              data.map((e) => BriefItem.fromJson(e as Map<String, dynamic>)));
          _nextCursor = nextCursor;
          _hasMore = nextCursor != null;
          _isLoadingMore = false;
        });
      } else {
        setState(() => _isLoadingMore = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _refresh() async {
    _nextCursor = null;
    _hasMore = true;
    await _fetchBriefs();
  }

  void _toggleLang() {
    setState(() {
      _lang = _lang == 'fr' ? 'en' : 'fr';
      _items = [];
    });
    _fetchBriefs();
  }

  String _dateLabel() {
    final now = DateTime.now();
    final day = now.day.toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    return '$day.$month';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          TerminalTopBar(
            label: 'FEED // ${_dateLabel()}',
            right: '${_items.length} BRIEFS',
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: TT.accent,
              backgroundColor: TT.surface,
              child: CustomScrollView(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Brief du jour header
                  SliverToBoxAdapter(child: _buildHeader()),

                  // Badge "NOUVEAUX ARTICLES"
                  if (_newArticlesCount > 0)
                    SliverToBoxAdapter(child: _buildNewBanner()),

                  if (_isLoading)
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, __) => const _SkeletonRow(),
                        childCount: 6,
                      ),
                    )
                  else if (_error != null)
                    SliverFillRemaining(child: _buildError(l10n))
                  else if (_items.isEmpty && !_quotaReached)
                    SliverFillRemaining(
                      child: Center(
                        child: Text(l10n.noArticles,
                            style: TT.mono(size: 12, color: TT.muted)),
                      ),
                    )
                  else ...[
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => BriefCard(
                          brief: _items[index],
                          isUserPremium: _isPremium,
                          onSubscribeTap: () =>
                              Navigator.pushNamed(context, '/subscribe'),
                        ),
                        childCount: _items.length,
                      ),
                    ),
                    if (_quotaReached && !_isPremium)
                      SliverToBoxAdapter(child: _buildPaywallBanner()),
                    if (_isLoadingMore)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                              child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: TT.accent, strokeWidth: 1.5))),
                        ),
                      ),
                  ],

                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildNewBanner() {
    return GestureDetector(
      onTap: () {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut);
        _refresh();
      },
      child: Container(
        color: TT.accent,
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 6, height: 6,
              margin: const EdgeInsets.only(right: 8),
              decoration: const BoxDecoration(
                  color: TT.bg, shape: BoxShape.circle),
            ),
            Text(
              '$_newArticlesCount NOUVEAU${_newArticlesCount > 1 ? 'X' : ''} · CHARGER',
              style: TT.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: TT.bg,
                  letterSpacing: 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final critCount = _items.where((i) => i.severity == Severity.critical).length;
    final subtitle = _items.isEmpty
        ? 'BRIEF DU JOUR · 2 MIN DE LECTURE'
        : 'BRIEF DU JOUR · $critCount CRITIQUE${critCount != 1 ? 'S' : ''}';

    // Sparkline basée sur les vraies données
    final hourCounts = List<int>.filled(24, 0);
    final now = DateTime.now();
    for (final item in _items) {
      final diff = now.difference(item.publishedAt);
      if (diff.inHours < 24) {
        final hour = 23 - diff.inHours.clamp(0, 23);
        hourCounts[hour]++;
      }
    }
    final maxCount = hourCounts.reduce((a, b) => a > b ? a : b).clamp(1, 999);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(subtitle,
                        style: TT.mono(size: 10, color: TT.muted, letterSpacing: 1)),
                  ),
                  // Toggle FR / EN
                  GestureDetector(
                    onTap: _toggleLang,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        border: Border.all(color: TT.accent, width: 1),
                      ),
                      child: Text(
                        _lang.toUpperCase(),
                        style: TT.mono(
                            size: 9,
                            weight: FontWeight.w700,
                            color: TT.accent,
                            letterSpacing: 1),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text('Le Brief',
                      style: TT.sans(
                          size: 28,
                          weight: FontWeight.w800,
                          color: TT.text,
                          letterSpacing: -0.6)),
                  const SizedBox(width: 8),
                  Text(
                    '// ${_items.length} menaces',
                    style: TT.mono(size: 11, color: TT.accent),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Sparkline sur les données réelles
              SizedBox(
                height: 30,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(24, (i) {
                    final h = (hourCounts[i] / maxCount * 28).clamp(2.0, 28.0);
                    final isRecent = i >= 18;
                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(right: 1),
                        height: h,
                        color: isRecent ? TT.accent : TT.line,
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('00:00', style: TT.mono(size: 9, color: TT.muted)),
                  Text('VOLUME · 24H', style: TT.mono(size: 9, color: TT.muted)),
                  Text(
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                    style: TT.mono(size: 9, color: TT.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: TT.line),
      ],
    );
  }

  Widget _buildError(AppLocalizations l10n) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('[ ERREUR RÉSEAU ]',
                style: TT.mono(size: 12, color: TT.red, letterSpacing: 1)),
            const SizedBox(height: 12),
            Text(l10n.connectionError,
                textAlign: TextAlign.center,
                style: TT.sans(size: 13, color: TT.muted, height: 1.5)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: _fetchBriefs,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(color: TT.accent),
                ),
                child: Text('RÉESSAYER',
                    style: TT.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: TT.accent,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaywallBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        border: Border.all(color: TT.accent, width: 1),
        color: TT.accent.withOpacity(0.06),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('// QUOTA ATTEINT',
              style: TT.mono(
                  size: 10,
                  weight: FontWeight.w700,
                  color: TT.accent,
                  letterSpacing: 1.5)),
          const SizedBox(height: 8),
          Text('5 briefs/jour en accès gratuit.\nAccès illimité avec Cybrief PRO.',
              style: TT.sans(size: 13, color: TT.text, height: 1.45)),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/subscribe'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              color: TT.accent,
              child: Text('ESSAI 7 JOURS · GRATUIT →',
                  textAlign: TextAlign.center,
                  style: TT.mono(
                      size: 12,
                      weight: FontWeight.w700,
                      color: TT.bg,
                      letterSpacing: 1)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('SANS ENGAGEMENT · ANNULE QUAND TU VEUX',
                style: TT.mono(size: 9, letterSpacing: 0.5)),
          ),
        ],
      ),
    );
  }
}

class _SkeletonRow extends StatefulWidget {
  const _SkeletonRow();
  @override
  State<_SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<_SkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.2, end: 0.5).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: TT.line)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
                width: 38, height: 20,
                color: TT.line.withOpacity(_anim.value)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(height: 8, width: 80,
                      color: TT.line.withOpacity(_anim.value)),
                  const SizedBox(height: 6),
                  Container(height: 14, color: TT.line.withOpacity(_anim.value)),
                  const SizedBox(height: 4),
                  Container(height: 10, width: double.infinity,
                      color: TT.line.withOpacity(_anim.value * 0.7)),
                  const SizedBox(height: 3),
                  Container(height: 10, width: 200,
                      color: TT.line.withOpacity(_anim.value * 0.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
