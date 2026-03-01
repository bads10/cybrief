import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'screens/login_screen.dart';
import 'screens/threat_feed_screen.dart';
import 'screens/threat_detail_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/stats_screen.dart';

void main() {
  runApp(const CybriefApp());
}

class CybriefApp extends StatelessWidget {
  const CybriefApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cybrief',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF135BEC),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF135BEC),
          secondary: Color(0xFF38BDF8),
          surface: Color(0xFF1E293B),
          onSurface: Colors.white,
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ).apply(
          bodyColor: Colors.white,
          displayColor: Colors.white,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/feed': (context) => const ThreatFeedScreen(),
        '/detail': (context) => const ThreatDetailScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/stats': (context) => const StatsScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A191E), // Darker teal/black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(height: 1, width: 30, color: const Color(0xFF135BEC).withValues(alpha: 0.3)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'NUMÉRO 001',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF38BDF8).withValues(alpha: 0.6),
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                  Container(height: 1, width: 30, color: const Color(0xFF135BEC).withValues(alpha: 0.3)),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                'Cybrief',
                style: GoogleFonts.libreBaskerville( // Using a serif font as per design
                  fontSize: 56,
                  fontWeight: FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: Colors.white,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.only(left: 12),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1)),
                ),
                child: Text(
                  'L\'intelligence cyber quotidienne, livrée avec précision et clarté.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                    color: Colors.white.withValues(alpha: 0.6),
                    height: 1.6,
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/feed'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12A9C9), // Teal/Cyan button
                  foregroundColor: const Color(0xFF0A191E),
                  minimumSize: const Size(double.infinity, 64),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Commencer',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {},
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'EXPLORER LES ARCHIVES',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withValues(alpha: 0.4),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(LucideIcons.chevronRight, size: 20, color: Colors.white.withValues(alpha: 0.4)),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildFooterLink('TWITTER'),
                    _buildFooterLink('LINKEDIN'),
                    _buildFooterLink('CONFIDENTIALITÉ'),
                    _buildFooterLink('CONDITIONS'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooterLink(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: Colors.white.withValues(alpha: 0.2),
        letterSpacing: 1.0,
      ),
    );
  }
}
