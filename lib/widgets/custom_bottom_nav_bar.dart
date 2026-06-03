import 'package:flutter/material.dart';
import '../theme/terminal_theme.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({super.key, required this.currentIndex});

  static const _routes = ['/flux', '/categories', '/stats', '/profile'];
  static const _labels = ['FLUX', 'INTEL', 'STATS', 'PARAM'];
  static const _icons  = [
    Icons.feed_outlined,
    Icons.shield_outlined,
    Icons.bar_chart_outlined,
    Icons.settings_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: TT.bg,
        border: Border(top: BorderSide(color: TT.line, width: 1)),
      ),
      padding: EdgeInsets.only(bottom: bottom > 0 ? bottom : 6),
      child: Row(
        children: List.generate(4, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                if (i == currentIndex) return;
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  _routes[i],
                  (route) => route.settings.name == '/flux',
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: active ? TT.accent : Colors.transparent,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icons[i],
                      size: 16,
                      color: active ? TT.accent : TT.muted,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _labels[i],
                      style: TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 9,
                        letterSpacing: 1,
                        color: active ? TT.accent : TT.muted,
                        fontWeight:
                            active ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
