import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/onboarding_screen.dart';
import 'screens/flux_screen.dart';
import 'screens/login_screen.dart';
import 'screens/threat_detail_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/stats_screen.dart';
import 'screens/paywall_screen.dart';
import 'services/subscription_service.dart';
import 'services/user_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBgDIF0uyElGVlAxazcCjZxz0PbbLYqAtM',
      appId: '1:694709746993:ios:0b9d764809618e34768410',
      messagingSenderId: '694709746993',
      projectId: 'gen-lang-client-0845651189',
      storageBucket: 'gen-lang-client-0845651189.firebasestorage.app',
      iosClientId: '694709746993-8jcdtq1ud1gem5ihdiki58untcjf1e2a.apps.googleusercontent.com',
      iosBundleId: 'com.badaoui.cybrief',
    ),
  );

  // Initialiser RevenueCat
  final uid = FirebaseAuth.instance.currentUser?.uid;
  await SubscriptionService.initialize(uid);

  // Enregistrer le token FCM pour les push notifications
  await _initFcm(uid);

  final prefs = await SharedPreferences.getInstance();
  final savedLang = prefs.getString('app_language') ?? 'fr';
  final initialScreen = await _getInitialRoute();

  runApp(CybriefApp(initialScreen: initialScreen, locale: Locale(savedLang)));
}

Future<void> _initFcm(String? uid) async {
  try {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final token = await messaging.getToken();
    if (token != null && uid != null) {
      await UserService.updateUser(uid, {'fcmToken': token});
    }
    messaging.onTokenRefresh.listen((newToken) {
      final currentUid = FirebaseAuth.instance.currentUser?.uid;
      if (currentUid != null) {
        UserService.updateUser(currentUid, {'fcmToken': newToken});
      }
    });
  } catch (e) {
    // FCM non critique — continuer même en cas d'erreur
  }
}

// Vérifie si l'onboarding a déjà été vu
Future<Widget> _getInitialRoute() async {
  final prefs = await SharedPreferences.getInstance();
  final done = prefs.getBool('onboarding_done') ?? false;
  final user = FirebaseAuth.instance.currentUser;

  if (!done) return const OnboardingScreen();
  if (user == null) return const LoginScreen();
  return const FluxScreen();
}

class CybriefApp extends StatefulWidget {
  final Widget initialScreen;
  final Locale locale;
  const CybriefApp({super.key, required this.initialScreen, required this.locale});

  static _CybriefAppState? of(BuildContext context) =>
      context.findAncestorStateOfType<_CybriefAppState>();

  @override
  State<CybriefApp> createState() => _CybriefAppState();
}

class _CybriefAppState extends State<CybriefApp> {
  late Locale _locale;

  @override
  void initState() {
    super.initState();
    _locale = widget.locale;
  }

  void setLocale(Locale locale) {
    setState(() => _locale = locale);
    SharedPreferences.getInstance().then(
      (p) => p.setString('app_language', locale.languageCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cybrief',
      debugShowCheckedModeBanner: false,
      locale: _locale,
      supportedLocales: const [Locale('fr'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
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
      home: widget.initialScreen,
      routes: {
        '/login': (context) => const LoginScreen(),
        '/flux': (context) => const FluxScreen(),
        '/detail': (context) => const ThreatDetailScreen(),
        '/signup': (context) => const SignupScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/categories': (context) => const CategoriesScreen(),
        '/stats': (context) => const StatsScreen(),
        '/subscribe': (context) => const PaywallScreen(),
      },
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A191E),
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
              const SizedBox(height: 24),
              Image.asset(
                'assets/images/logo.png',
                width: 260,
                height: 260,
                fit: BoxFit.contain,
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
              // ── Bouton principal → /login ──────────────────────────────
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12A9C9),
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
              // ── Accès direct sans compte ───────────────────────────────
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/flux'),
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
