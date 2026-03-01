import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'article_browser_screen.dart';
import 'threat_feed_screen.dart';

class ThreatDetailScreen extends StatelessWidget {
  const ThreatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final article = ModalRoute.of(context)?.settings.arguments as Article?;

    if (article == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        appBar: AppBar(
          backgroundColor: const Color(0xFF0F172A),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.fileX, color: Colors.white24, size: 40),
              const SizedBox(height: 16),
              Text('Article introuvable',
                  style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
            ],
          ),
        ),
      );
    }

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

    final tags = article.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final cves = article.cve
        .split(',')
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();

    final affected = article.affectedSystems
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final iocList = article.iocs
        .split('|')
        .map((i) => i.trim())
        .where((i) => i.isNotEmpty)
        .toList();

    // Y a-t-il des infos techniques à afficher ?
    final hasTechInfo = cves.isNotEmpty ||
        article.attackType.isNotEmpty ||
        affected.isNotEmpty;
    final hasIocs = iocList.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),

      // ── AppBar ────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leadingWidth: 120,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.chevronLeft, color: Colors.white, size: 22),
                const SizedBox(width: 4),
                Text(
                  'Retour',
                  style: GoogleFonts.inter(
                      color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.bookmark, size: 20, color: Colors.white54),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),

      // ── Corps scrollable ──────────────────────────────────────
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Badge sévérité + temps ────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: severityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: severityColor.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 7, color: severityColor),
                      const SizedBox(width: 6),
                      Text(
                        article.criticality.toUpperCase(),
                        style: TextStyle(
                          color: severityColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Text('•',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.25))),
                const SizedBox(width: 10),
                Text(
                  article.timeAgo,
                  style: GoogleFonts.inter(
                      color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── Titre ─────────────────────────────────────────
            Text(
              article.title,
              style: GoogleFonts.inter(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                height: 1.25,
                letterSpacing: -0.4,
                color: Colors.white,
              ),
            ),

            // ── Tags ──────────────────────────────────────────
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: tags
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(tag,
                              style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontWeight: FontWeight.w500)),
                        ))
                    .toList(),
              ),
            ],

            const SizedBox(height: 24),
            _Divider(),

            // ── Résumé ────────────────────────────────────────
            _SectionLabel('RÉSUMÉ', LucideIcons.fileText),
            const SizedBox(height: 10),
            Text(
              article.summary.isNotEmpty
                  ? article.summary
                  : 'Aucun résumé disponible.',
              style: GoogleFonts.inter(
                fontSize: 15,
                color: Colors.white.withValues(alpha: 0.85),
                height: 1.65,
              ),
            ),

            // ── Informations techniques ────────────────────────
            if (hasTechInfo) ...[
              const SizedBox(height: 24),
              _Divider(),
              _SectionLabel('INFORMATIONS TECHNIQUES', LucideIcons.cpu),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    if (article.attackType.isNotEmpty)
                      _TechRow(
                        icon: LucideIcons.zap,
                        label: 'Type d\'attaque',
                        value: article.attackType,
                        iconColor: Colors.orangeAccent,
                        isFirst: true,
                        isLast: cves.isEmpty && affected.isEmpty,
                      ),
                    if (cves.isNotEmpty)
                      _TechRow(
                        icon: LucideIcons.shieldAlert,
                        label: 'CVE',
                        value: cves.join('  •  '),
                        iconColor: Colors.redAccent,
                        isFirst: article.attackType.isEmpty,
                        isLast: affected.isEmpty,
                        monospace: true,
                        copiable: true,
                      ),
                    if (affected.isNotEmpty)
                      _TechRow(
                        icon: LucideIcons.monitor,
                        label: 'Systèmes affectés',
                        value: affected.join(', '),
                        iconColor: const Color(0xFF38BDF8),
                        isFirst: article.attackType.isEmpty && cves.isEmpty,
                        isLast: true,
                      ),
                  ],
                ),
              ),
            ],

            // ── Indicateurs de compromission ───────────────────
            if (hasIocs) ...[
              const SizedBox(height: 24),
              _Divider(),
              _SectionLabel('INDICATEURS DE COMPROMISSION', LucideIcons.octagonAlert),
              const SizedBox(height: 12),
              ...iocList.map((ioc) => _IocCard(ioc: ioc)),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),

      // ── Bouton fixe en bas ────────────────────────────────────
      bottomNavigationBar: article.url.isNotEmpty
          ? _StickyBrowserBar(article: article)
          : const SizedBox.shrink(),
    );
  }
}

// ─── Widgets utilitaires ────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: Colors.white.withValues(alpha: 0.07),
        margin: const EdgeInsets.only(bottom: 18),
      );
}

class _SectionLabel extends StatelessWidget {
  final String text;
  final IconData icon;
  const _SectionLabel(this.text, this.icon);

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF6366F1).withValues(alpha: 0.7)),
          const SizedBox(width: 7),
          Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF6366F1).withValues(alpha: 0.7),
              letterSpacing: 0.9,
            ),
          ),
        ],
      );
}

class _TechRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final bool isFirst;
  final bool isLast;
  final bool monospace;
  final bool copiable;

  const _TechRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
    this.isFirst = false,
    this.isLast = false,
    this.monospace = false,
    this.copiable = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: copiable
          ? () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copié : $value',
                      style: GoogleFonts.inter(fontSize: 13)),
                  backgroundColor: const Color(0xFF1E293B),
                  duration: const Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : Border(
                  bottom: BorderSide(
                      color: Colors.white.withValues(alpha: 0.05))),
          borderRadius: BorderRadius.vertical(
            top: isFirst ? const Radius.circular(12) : Radius.zero,
            bottom: isLast ? const Radius.circular(12) : Radius.zero,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, size: 14, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.4),
                        fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: monospace
                        ? GoogleFonts.jetBrainsMono(
                            fontSize: 13,
                            color: Colors.redAccent.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                          )
                        : GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                  ),
                ],
              ),
            ),
            if (copiable)
              Icon(LucideIcons.copy,
                  size: 14, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}

class _IocCard extends StatelessWidget {
  final String ioc;
  const _IocCard({required this.ioc});

  @override
  Widget build(BuildContext context) {
    // Parse "Type:valeur" ou juste "valeur"
    final colonIdx = ioc.indexOf(':');
    final hasLabel = colonIdx > 0 && colonIdx < 20;
    final label = hasLabel ? ioc.substring(0, colonIdx).trim() : 'IOC';
    final value = hasLabel ? ioc.substring(colonIdx + 1).trim() : ioc;

    Color labelColor;
    IconData labelIcon;
    switch (label.toLowerCase()) {
      case 'hash':
      case 'sha256':
      case 'md5':
        labelColor = const Color(0xFFFBBF24);
        labelIcon = LucideIcons.hash;
        break;
      case 'ip':
        labelColor = Colors.redAccent;
        labelIcon = LucideIcons.globe;
        break;
      case 'domaine':
      case 'domain':
        labelColor = Colors.orangeAccent;
        labelIcon = LucideIcons.link;
        break;
      case 'url':
        labelColor = const Color(0xFF38BDF8);
        labelIcon = LucideIcons.externalLink;
        break;
      default:
        labelColor = Colors.white54;
        labelIcon = LucideIcons.shieldAlert;
    }

    return GestureDetector(
      onLongPress: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copié : ${value.length > 40 ? '${value.substring(0, 40)}…' : value}',
                style: GoogleFonts.inter(fontSize: 13)),
            backgroundColor: const Color(0xFF1E293B),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: labelColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: labelColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(labelIcon, size: 13, color: labelColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label.toUpperCase(),
                      style: GoogleFonts.inter(
                          fontSize: 9,
                          color: labelColor.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.jetBrainsMono(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(LucideIcons.copy,
                size: 13, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }
}

/// Barre fixe en bas — toujours visible
class _StickyBrowserBar extends StatelessWidget {
  final Article article;
  const _StickyBrowserBar({required this.article});

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, 14 + bottomPadding),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
      ),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArticleBrowserScreen(url: article.url, title: article.title),
          ),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF135BEC).withValues(alpha: 0.18),
                const Color(0xFF38BDF8).withValues(alpha: 0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: const Color(0xFF38BDF8).withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.globe, color: Color(0xFF38BDF8), size: 18),
              const SizedBox(width: 10),
              Text(
                "Lire l'article source",
                style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 8),
              const Icon(LucideIcons.arrowRight,
                  color: Color(0xFF38BDF8), size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
