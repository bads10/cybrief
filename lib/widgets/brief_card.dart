import 'package:flutter/material.dart';
import '../models/brief_item.dart';
import '../screens/threat_detail_screen.dart';
import '../theme/terminal_theme.dart';
import 'terminal_widgets.dart';

class BriefCard extends StatelessWidget {
  final BriefItem brief;
  final bool isUserPremium;
  final VoidCallback? onSubscribeTap;

  const BriefCard({
    super.key,
    required this.brief,
    this.isUserPremium = false,
    this.onSubscribeTap,
  });

  String get _sevLevel => TerminalSevTag.fromSeverity(brief.severity);

  String get _tag {
    if (brief.cveTag != null && brief.cveTag!.isNotEmpty) return brief.cveTag!;
    if (brief.mitreTag != null && brief.mitreTag!.isNotEmpty) return brief.mitreTag!;
    return _sevLevel;
  }

  String _timeAgo() {
    final now = DateTime.now();
    final diff = now.difference(brief.publishedAt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    // Même jour → heure exacte
    final pub = brief.publishedAt;
    if (pub.year == now.year && pub.month == now.month && pub.day == now.day) {
      final h = pub.hour.toString().padLeft(2, '0');
      final m = pub.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays == 1) return 'hier';
    if (diff.inDays < 7) return '${diff.inDays}j';
    return '${pub.day.toString().padLeft(2, '0')}/${pub.month.toString().padLeft(2, '0')}';
  }

  String _readTime() {
    final words = brief.body.split(' ').length;
    final mins = (words / 200).ceil().clamp(1, 60);
    return '$mins min';
  }

  @override
  Widget build(BuildContext context) {
    final locked = brief.isPremium && !isUserPremium;

    return GestureDetector(
      onTap: locked
          ? onSubscribeTap
          : () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ThreatDetailScreen(),
                  settings: RouteSettings(arguments: brief),
                ),
              ),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TT.line, width: 1)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: locked ? _lockedRow() : _normalRow(),
      ),
    );
  }

  Widget _normalRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left col: sev + time
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TerminalSevTag(level: _sevLevel),
              const SizedBox(height: 4),
              Text(_timeAgo(),
                  style: TT.mono(size: 9, color: TT.muted)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Center col: content
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_tag.toUpperCase()} · ${brief.source.toUpperCase()}',
                style: TT.mono(size: 9, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                brief.headline,
                style: TT.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: TT.text,
                    height: 1.3),
              ),
              const SizedBox(height: 6),
              Text(
                brief.body,
                style: TT.sans(size: 12, color: TT.muted, height: 1.45),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (_tag.startsWith('CVE') || brief.mitreTag != null) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 4,
                  children: [
                    if (_tag.startsWith('CVE'))
                      _tagChip(_tag),
                    if (brief.mitreTag != null)
                      _tagChip(brief.mitreTag!),
                  ],
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        // Right col: read time
        Text(_readTime(), style: TT.mono(size: 9, color: TT.muted)),
      ],
    );
  }

  Widget _lockedRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 54,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TerminalSevTag(level: _sevLevel),
              const SizedBox(height: 4),
              Text(_timeAgo(), style: TT.mono(size: 9, color: TT.muted)),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_tag.toUpperCase()} · ${brief.source.toUpperCase()}',
                style: TT.mono(size: 9, letterSpacing: 0.5),
              ),
              const SizedBox(height: 2),
              Text(
                brief.headline,
                style: TT.sans(
                    size: 14,
                    weight: FontWeight.w600,
                    color: TT.muted,
                    height: 1.3),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onSubscribeTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: TT.accent.withOpacity(0.1),
                    border: Border.all(color: TT.accent, width: 1),
                  ),
                  child: Text('PRO →',
                      style: TT.mono(
                          size: 10,
                          weight: FontWeight.w700,
                          color: TT.accent,
                          letterSpacing: 1)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        const Icon(Icons.lock_outline, size: 12, color: TT.muted),
      ],
    );
  }

  Widget _tagChip(String label) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
        decoration: BoxDecoration(
          border: Border.all(color: TT.line, width: 1),
        ),
        child: Text(label,
            style: TT.mono(size: 9, color: TT.muted, letterSpacing: 0.3)),
      );
}
