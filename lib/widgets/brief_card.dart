import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/brief_item.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class BriefCard extends StatefulWidget {
  final BriefItem brief;
  final bool isUserPremium;
  final VoidCallback? onSubscribeTap;

  const BriefCard({
    super.key,
    required this.brief,
    this.isUserPremium = false,
    this.onSubscribeTap,
  });

  @override
  State<BriefCard> createState() => _BriefCardState();
}

class _BriefCardState extends State<BriefCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _expandAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleExpand() {
    setState(() => _isExpanded = !_isExpanded);
    _isExpanded ? _controller.forward() : _controller.reverse();
  }

  // ─── Couleurs selon sévérité ──────────────────────────────────────────────
  Color get _severityColor {
    switch (widget.brief.severity) {
      case Severity.critical: return AppColors.critical;
      case Severity.high:     return AppColors.high;
      case Severity.medium:   return AppColors.medium;
      case Severity.low:      return AppColors.low;
    }
  }

  Color get _severityBg {
    switch (widget.brief.severity) {
      case Severity.critical: return AppColors.criticalBg;
      case Severity.high:     return AppColors.highBg;
      case Severity.medium:   return AppColors.mediumBg;
      case Severity.low:      return AppColors.lowBg;
    }
  }

  // ─── Indicateur latéral gauche (bordure colorée comme badge sévérité) ─────
  Widget _buildLeftBorder() {
    return Container(
      width: 3,
      decoration: BoxDecoration(
        color: _severityColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomLeft: Radius.circular(12),
        ),
      ),
    );
  }

  // ─── Header : tag sévérité + time + tags MITRE/CVE ───────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Tag sévérité (= tag "1ER-MAI" de Brief.me)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _severityBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: _severityColor.withOpacity(0.4)),
          ),
          child: Text(
            widget.brief.severity.label,
            style: AppTextStyles.mono.copyWith(color: _severityColor),
          ),
        ),
        const Spacer(),
        // Tags MITRE / CVE (monospace — côté geek)
        if (widget.brief.cveTag != null) ...[
          _buildMonoTag(widget.brief.cveTag!, AppColors.cyan),
          const SizedBox(width: 6),
        ],
        if (widget.brief.mitreTag != null)
          _buildMonoTag(widget.brief.mitreTag!, AppColors.textMuted),
        const SizedBox(width: 8),
        // Timestamp
        Text(
          _formatTime(widget.brief.publishedAt),
          style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildMonoTag(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: AppTextStyles.mono.copyWith(color: color),
      ),
    );
  }

  // ─── Corps principal ──────────────────────────────────────────────────────
  Widget _buildBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline (toujours visible)
        Text(widget.brief.headline, style: AppTextStyles.headline),
        const SizedBox(height: 8),
        // Body (tronqué si collapsed)
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Text(
            widget.brief.body,
            style: AppTextStyles.body,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          secondChild: Text(
            widget.brief.body,
            style: AppTextStyles.body,
          ),
        ),
      ],
    );
  }

  // ─── Section expanded : Why + Action ─────────────────────────────────────
  Widget _buildExpandedDetails() {
    return SizeTransition(
      sizeFactor: _expandAnimation,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          _buildDivider(),
          const SizedBox(height: 12),
          // Pourquoi c'est important
          _buildDetailRow(
            icon: '⚡',
            label: 'Pourquoi c\'est grave',
            content: widget.brief.whyMatters,
            contentColor: AppColors.textPrimary,
          ),
          const SizedBox(height: 10),
          // Action recommandée
          _buildDetailRow(
            icon: '🔧',
            label: 'Quoi faire',
            content: widget.brief.action,
            contentColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String icon,
    required String label,
    required String content,
    required Color contentColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: AppTextStyles.mono.copyWith(
                  color: AppColors.textMuted,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: AppTextStyles.body.copyWith(
                  color: contentColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Footer : source + expand toggle ─────────────────────────────────────
  Widget _buildFooter() {
    return Row(
      children: [
        // Lien source (= "Lire la suite" de Brief.me)
        GestureDetector(
          onTap: () => launchUrl(Uri.parse(widget.brief.sourceUrl)),
          child: Row(
            children: [
              Icon(Icons.link, size: 13, color: AppColors.cyan),
              const SizedBox(width: 4),
              Text(
                widget.brief.source,
                style: AppTextStyles.label.copyWith(
                  color: AppColors.cyan,
                  decoration: TextDecoration.underline,
                  decorationColor: AppColors.cyan,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward, size: 12, color: AppColors.cyan),
            ],
          ),
        ),
        const Spacer(),
        // Toggle expand / collapse
        GestureDetector(
          onTap: _toggleExpand,
          child: Row(
            children: [
              Text(
                _isExpanded ? 'Réduire' : 'Détails',
                style: AppTextStyles.label.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  size: 16,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Overlay Premium ──────────────────────────────────────────────────────
  Widget _buildPremiumOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Flou gaussien
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.surface.withOpacity(0.1),
                    AppColors.surface.withOpacity(0.97),
                  ],
                  stops: const [0.0, 0.45],
                ),
              ),
            ),
            // Contenu CTA
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.cyanSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cyan, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.lock_outline,
                      color: AppColors.cyan,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Brief Premium',
                    style: AppTextStyles.headline.copyWith(fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Accès complet avec l\'abonnement',
                    style: AppTextStyles.label.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: widget.onSubscribeTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.ctaOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Essayer 30 jours gratuits',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────
  Widget _buildDivider() => Container(
    height: 1,
    color: AppColors.border,
  );

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}min';
    if (diff.inHours < 24)   return 'Il y a ${diff.inHours}h';
    return 'Il y a ${diff.inDays}j';
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final bool showLocked =
        widget.brief.isPremium && !widget.isUserPremium;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          // Card principale
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border, width: 1),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bordure gauche colorée (indicateur sévérité)
                  _buildLeftBorder(),
                  // Contenu
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 10),
                          _buildBody(),
                          _buildExpandedDetails(),
                          const SizedBox(height: 12),
                          _buildDivider(),
                          const SizedBox(height: 10),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Overlay premium par-dessus
          if (showLocked) _buildPremiumOverlay(),
        ],
      ),
    );
  }
}
