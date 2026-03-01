import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF38BDF8),
        unselectedItemColor: Colors.white.withValues(alpha: 0.4),
        currentIndex: currentIndex,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        unselectedLabelStyle: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
        onTap: (index) {
          if (index == currentIndex) return;

          const routes = ['/feed', '/categories', '/stats', '/profile'];
          final target = routes[index];

          // Garde /feed comme base de pile — les onglets s'empilent dessus
          // Retour sur n'importe quel onglet ramène toujours à /feed
          Navigator.pushNamedAndRemoveUntil(
            context,
            target,
            (route) => route.settings.name == '/feed',
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.rss, size: 20),
            ),
            label: 'FLUX',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.shield, size: 20),
            ),
            label: 'INTEL',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.chartBarBig, size: 20),
            ),
            label: 'STATS',
          ),
          BottomNavigationBarItem(
            icon: Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(LucideIcons.settings, size: 20),
            ),
            label: 'PARAMÈTRES',
          ),
        ],
      ),
    );
  }
}
