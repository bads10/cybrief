import 'dart:convert';
import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
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
  static const int _pageSize = 20;

  final ScrollController _scrollCtrl = ScrollController();

  List<BriefItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isPremium = false;
  bool _quotaReached = false;
  String? _error;
  String? _nextCursor;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 &&
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
        UserService.syncUser(uid: user.uid, email: user.email ?? '', displayName: user.displayName),
        _checkPremium(),
      ]);
    }
    await _fetchBriefs();
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
    return Uri.parse('$kApiBaseUrl/api/articles').replace(queryParameters: params);
  }

  Future<void> _fetchBriefs() async {
    setState(() { _isLoading = true; _error = null; _nextCursor = null; _hasMore = true; });
    try {
      final response = await http.get(_buildUri()).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        // API returns either {articles:[...], nextCursor:...} or a raw array
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
          _items = data.map((e) => BriefItem.fromJson(e as Map<String, dynamic>)).toList();
          _quotaReached = quotaReached;
          _nextCursor = nextCursor;
          _hasMore = nextCursor != null;
          _isLoading = false;
        });
      } else {
        setState(() { _error = 'Erreur serveur (${response.statusCode})'; _isLoading = false; });
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'error'; _isLoading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _nextCursor == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final response = await http.get(_buildUri(cursor: _nextCursor))
          .timeout(const Duration(seconds: 10));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List data = body is List ? body : (body['articles'] as List? ?? []);
        final String? nextCursor = body is Map ? body['nextCursor'] as String? : null;
        setState(() {
          _items.addAll(data.map((e) => BriefItem.fromJson(e as Map<String, dynamic>)));
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

  String _getFormattedDate(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    if (locale == 'fr') {
      const jours = ['LUNDI','MARDI','MERCREDI','JEUDI','VENDREDI','SAMEDI','DIMANCHE'];
      const mois = ['JANVIER','FÉVRIER','MARS','AVRIL','MAI','JUIN','JUILLET','AOÛT','SEPTEMBRE','OCTOBRE','NOVEMBRE','DÉCEMBRE'];
      return '${jours[now.weekday - 1]} ${now.day} ${mois[now.month - 1]}';
    }
    const days = ['MONDAY','TUESDAY','WEDNESDAY','THURSDAY','FRIDAY','SATURDAY','SUNDAY'];
    const months = ['JANUARY','FEBRUARY','MARCH','APRIL','MAY','JUNE','JULY','AUGUST','SEPTEMBER','OCTOBER','NOVEMBER','DECEMBER'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(l10n.appName, style: AppTextStyles.headline.copyWith(fontSize: 20, letterSpacing: -0.5)),
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
        onRefresh: _refresh,
        color: AppColors.cyan,
        backgroundColor: AppColors.surfaceElevated,
        child: CustomScrollView(
          controller: _scrollCtrl,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_getFormattedDate(context), style: AppTextStyles.label.copyWith(
                      color: AppColors.cyan, fontWeight: FontWeight.w700, letterSpacing: 1.5,
                    )),
                    const SizedBox(height: 8),
                    Text(l10n.dailyBriefTitle, style: AppTextStyles.headline.copyWith(fontSize: 32, height: 1.1)),
                    const SizedBox(height: 8),
                    Text(l10n.tagline, style: AppTextStyles.body.copyWith(
                      fontSize: 16, color: AppColors.textSecondary,
                    )),
                  ],
                ),
              ),
            ),

            if (_isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const _SkeletonCard(),
                  childCount: 5,
                ),
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
                        Text(l10n.connectionError, textAlign: TextAlign.center, style: AppTextStyles.body),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _fetchBriefs,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.cyanSurface,
                            foregroundColor: AppColors.cyan,
                          ),
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_items.isEmpty && !_quotaReached)
              SliverFillRemaining(
                child: Center(child: Text(l10n.noArticles, style: AppTextStyles.body)),
              )
            else ...[
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
              if (_quotaReached && !_isPremium)
                SliverToBoxAdapter(child: _buildPaywallBanner(l10n)),
              if (_isLoadingMore)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator(color: AppColors.cyan, strokeWidth: 2)),
                  ),
                ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildPaywallBanner(AppLocalizations l10n) {
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
            Text(l10n.quotaReachedTitle, textAlign: TextAlign.center,
              style: AppTextStyles.headline.copyWith(fontSize: 18)),
            const SizedBox(height: 8),
            Text(l10n.quotaReachedBody, textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity, height: 48,
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
                  child: Text(l10n.startFreeTrial,
                    style: AppTextStyles.label.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(l10n.premiumMonthlyPrice,
              style: AppTextStyles.label.copyWith(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _SkeletonCard extends StatefulWidget {
  const _SkeletonCard();
  @override
  State<_SkeletonCard> createState() => _SkeletonCardState();
}

class _SkeletonCardState extends State<_SkeletonCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _box(60, 22, radius: 6),
                const SizedBox(width: 8),
                _box(80, 16, radius: 4),
              ]),
              const SizedBox(height: 16),
              _box(double.infinity, 20, radius: 4),
              const SizedBox(height: 8),
              _box(double.infinity * 0.8, 20, radius: 4),
              const SizedBox(height: 12),
              _box(double.infinity, 14, radius: 4),
              const SizedBox(height: 6),
              _box(200, 14, radius: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _box(double width, double height, {double radius = 4}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: _anim.value * 0.15),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
