import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/onboarding_slide.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {

  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ─── Slides ───────────────────────────────────────────────────────────────
  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      lottieAsset: 'assets/lottie/shield_pulse.json',
      title: 'La cybermenace\nen 2 minutes.',
      subtitle: 'Chaque matin, le brief cyber\ndes pros de la sécurité.',
      backgroundColor: AppColors.background,
      titleColor: AppColors.textPrimary,
    ),
    OnboardingSlide(
      lottieAsset: 'assets/lottie/terminal_typing.json',
      title: 'Des briefs,\npas du bruit.',
      subtitle: 'Sélectionné, analysé, contextualisé\nselon MITRE ATT&CK.',
      backgroundColor: AppColors.surface,
      titleColor: AppColors.textPrimary,
    ),
    OnboardingSlide(
      lottieAsset: 'assets/lottie/lock_check.json',
      title: 'Indépendant.\nSans pub.',
      subtitle: 'Cybrief est financé par ses abonnés.\nVos données ne sont jamais revendues.',
      backgroundColor: AppColors.background,
      titleColor: AppColors.textPrimary,
    ),
    OnboardingSlide(
      lottieAsset: 'assets/lottie/gift_unlock.json',
      title: 'Essai gratuit\n30 jours.',
      subtitle: 'Sans engagement.\nSans carte bancaire.',
      backgroundColor: AppColors.cyanSurface,
      titleColor: AppColors.cyan,
    ),
  ];

  // ─── Navigation ───────────────────────────────────────────────────────────
  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToAuth(isSignUp: true);
    }
  }

  Future<void> _navigateToAuth({required bool isSignUp}) async {
    // Marque onboarding comme vu
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isSignUp ? '/signup' : '/login',
    );
  }

  // ─── Builders ─────────────────────────────────────────────────────────────

  // Slide individuelle
  Widget _buildSlide(OnboardingSlide slide, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: slide.backgroundColor,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Animation Lottie
              Expanded(
                flex: 5,
                child: Lottie.asset(
                  slide.lottieAsset,
                  repeat: true,
                  animate: _currentPage == index,
                ),
              ),

              // Titre + sous-titre
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      slide.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: slide.titleColor,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      slide.subtitle,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),

              // Espace pour le CTA fixe en bas
              const SizedBox(height: 140),
            ],
          ),
        ),
      ),
    );
  }

  // Points de progression animés
  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final bool isActive = index == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: isActive ? AppColors.cyan : AppColors.textMuted,
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }

  // Bouton CTA principal
  Widget _buildCTAButton() {
    final bool isLastSlide = _currentPage == _slides.length - 1;
    return GestureDetector(
      onTap: _nextPage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: isLastSlide ? AppColors.ctaOrange : AppColors.cyan,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: (isLastSlide ? AppColors.ctaOrange : AppColors.cyan)
                  .withOpacity(0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Text(
            isLastSlide ? 'S\'inscrire' : 'Suivant',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // Lien "Me connecter" / "Passer"
  Widget _buildSecondaryAction() {
    final bool isLastSlide = _currentPage == _slides.length - 1;
    return TextButton(
      onPressed: () => isLastSlide
          ? _navigateToAuth(isSignUp: false)
          : _navigateToAuth(isSignUp: false),
      child: Text(
        isLastSlide ? 'Me connecter' : 'Passer',
        style: AppTextStyles.label.copyWith(
          color: AppColors.textSecondary,
          decoration: TextDecoration.underline,
          decorationColor: AppColors.textMuted,
        ),
      ),
    );
  }

  // Bloc CTA fixe en bas (ne scroll pas)
  Widget _buildBottomCTA() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _slides[_currentPage].backgroundColor.withOpacity(0),
            _slides[_currentPage].backgroundColor,
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDots(),
            const SizedBox(height: 20),
            _buildCTAButton(),
            const SizedBox(height: 8),
            _buildSecondaryAction(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Indicateur de swipe (première slide seulement) ─────────────────────
  Widget _buildSwipeHint() {
    if (_currentPage != 0) return const SizedBox.shrink();
    return Positioned(
      bottom: 160,
      left: 0,
      right: 0,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) => Opacity(
          opacity: value * 0.4,
          child: child,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.swipe_left, size: 14, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(
              'Glisser pour continuer',
              style: AppTextStyles.mono.copyWith(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // Masque la status bar pour immersion totale
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: _slides[_currentPage].backgroundColor,
      body: Stack(
        children: [
          // PageView principal
          PageView.builder(
            controller: _pageController,
            onPageChanged: (page) => setState(() => _currentPage = page),
            itemCount: _slides.length,
            itemBuilder: (context, index) =>
                _buildSlide(_slides[index], index),
          ),

          // Hint swipe
          _buildSwipeHint(),

          // CTA fixe en bas — par-dessus le PageView
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomCTA(),
          ),
        ],
      ),
    );
  }
}
