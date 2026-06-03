import 'package:flutter/material.dart';
import '../theme/terminal_theme.dart';
import '../models/brief_item.dart';

// ── TopBar (44dp height, back-aware) ──────────────────────
class TerminalTopBar extends StatefulWidget {
  final String label;
  final String right;
  /// Callback back explicite — sinon Navigator.pop si label commence par '<'
  final VoidCallback? onBack;
  /// Callback pour tap sur la zone droite (ex: refresh)
  final VoidCallback? onRightTap;

  const TerminalTopBar({
    super.key,
    required this.label,
    this.right = '',
    this.onBack,
    this.onRightTap,
  });

  @override
  State<TerminalTopBar> createState() => _TerminalTopBarState();
}

class _TerminalTopBarState extends State<TerminalTopBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 1.0, end: 0.3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBack = widget.label.trimLeft().startsWith('<') || widget.onBack != null;

    Widget leftWidget = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBack
          ? (widget.onBack ?? () => Navigator.maybePop(context))
          : null,
      child: Container(
        constraints: const BoxConstraints(minWidth: 80, minHeight: 44),
        alignment: Alignment.centerLeft,
        child: Text(
          widget.label,
          style: TT.mono(
            size: 11,
            weight: isBack ? FontWeight.w700 : FontWeight.w400,
            letterSpacing: 0.5,
            color: isBack ? TT.text : TT.muted,
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 44,
          decoration: const BoxDecoration(
            color: TT.bg,
            border: Border(bottom: BorderSide(color: TT.line, width: 1)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              leftWidget,
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: _anim,
                      child: Container(
                        width: 6, height: 6,
                        decoration: const BoxDecoration(
                            color: TT.green, shape: BoxShape.circle),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('LIVE', style: TT.mono(size: 10, letterSpacing: 0.5)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onRightTap,
                behavior: HitTestBehavior.opaque,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 80, minHeight: 44),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      widget.right,
                      textAlign: TextAlign.right,
                      style: TT.mono(
                        size: 10,
                        letterSpacing: 0.5,
                        color: widget.right.startsWith('✓')
                            ? TT.green
                            : widget.onRightTap != null
                                ? TT.accent
                                : TT.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}

// ── SevTag badge ──────────────────────────────────────────
class TerminalSevTag extends StatelessWidget {
  final String level; // 'CRIT' | 'HIGH' | 'MED' | 'LOW'

  const TerminalSevTag({super.key, required this.level});

  static String fromSeverity(Severity s) {
    switch (s) {
      case Severity.critical: return 'CRIT';
      case Severity.high:     return 'HIGH';
      case Severity.medium:   return 'MED';
      case Severity.low:      return 'LOW';
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = TT.sevColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        border: Border.all(color: c, width: 1),
      ),
      child: Text(level,
          style: TT.mono(
              size: 10, weight: FontWeight.w700, color: c, letterSpacing: 0.8)),
    );
  }
}

// ── Toggle switch (V1 style) ──────────────────────────────
class TerminalToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const TerminalToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: Container(
        width: 32, height: 18,
        decoration: BoxDecoration(
          color: value ? TT.accent : TT.line,
          borderRadius: BorderRadius.circular(99),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 150),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(2),
            width: 14, height: 14,
            decoration: const BoxDecoration(
                color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
