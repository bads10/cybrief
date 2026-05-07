import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  Offerings? _offerings;
  Package? _selectedPackage;
  bool _loading = true;
  bool _purchasing = false;
  bool _yearlySelected = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    final offerings = await SubscriptionService.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _loading = false;
        if (offerings?.current != null) {
          final packages = offerings!.current!.availablePackages;
          final yearly = _findPackage(packages, '\$rc_annual', PackageType.annual);
          final monthly = _findPackage(packages, '\$rc_monthly', PackageType.monthly);
          _selectedPackage = yearly ?? monthly;
        }
      });
    }
  }

  Future<void> _purchase() async {
    if (_selectedPackage == null) return;
    setState(() { _purchasing = true; _error = null; });

    final result = await SubscriptionService.purchasePackage(_selectedPackage!);

    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result.success) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await UserService.updateUser(uid, {'subscriptionStatus': 'premium'});
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 Bienvenue dans Cybrief Premium !', style: GoogleFonts.inter()),
          backgroundColor: const Color(0xFF22C55E),
        ));
      }
    } else if (result.error != null) {
      setState(() => _error = result.error);
    }
  }

  Future<void> _restore() async {
    setState(() { _purchasing = true; _error = null; });
    final result = await SubscriptionService.restorePurchases();
    if (!mounted) return;
    setState(() => _purchasing = false);

    if (result.success) {
      Navigator.pop(context);
    } else {
      setState(() => _error = result.error ?? 'Aucun abonnement à restaurer.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  Text('CYBRIEF PREMIUM', style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.bold,
                    color: Colors.white.withValues(alpha: 0.5), letterSpacing: 2,
                  )),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(LucideIcons.x, size: 18, color: Colors.white.withValues(alpha: 0.6)),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Column(
                  children: [
                    // Animation
                    SizedBox(
                      height: 120,
                      child: Lottie.asset('assets/lottie/gift_unlock.json', fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 20),

                    // Titre
                    Text(
                      'Intelligence cyber\nsans limites',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Rejoins les professionnels de la sécurité\nqui ne manquent aucune menace.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14, color: Colors.white.withValues(alpha: 0.5), height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Features
                    _buildFeatures(),
                    const SizedBox(height: 32),

                    // Plans
                    if (_loading)
                      const CircularProgressIndicator(color: Color(0xFF38BDF8))
                    else
                      _buildPlans(),

                    const SizedBox(height: 24),

                    // CTA principal
                    _buildCTA(),

                    const SizedBox(height: 12),

                    // Erreur
                    if (_error != null)
                      Text(_error!, style: GoogleFonts.inter(
                        color: const Color(0xFFEF4444), fontSize: 13,
                      ), textAlign: TextAlign.center),

                    const SizedBox(height: 16),

                    // Restaurer + mentions légales
                    TextButton(
                      onPressed: _purchasing ? null : _restore,
                      child: Text('Restaurer mes achats', style: GoogleFonts.inter(
                        fontSize: 13, color: Colors.white.withValues(alpha: 0.4),
                      )),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sans engagement · Annulable à tout moment\nRenouvellement automatique sauf résiliation 24h avant.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11, color: Colors.white.withValues(alpha: 0.25), height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatures() {
    final features = [
      (LucideIcons.infinity, 'Articles illimités', 'Feed complet sans quota journalier'),
      (LucideIcons.shieldAlert, 'CVE & IOC complets', 'Indicateurs techniques exhaustifs'),
      (LucideIcons.zap, 'Alertes temps réel', 'Push pour chaque menace critique'),
      (LucideIcons.mail, 'Newsletter quotidienne', 'Briefing cyber dans ta boîte mail'),
      (LucideIcons.fileText, 'Analyses Threat Intel', 'Sources Talos, Mandiant, Unit42…'),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        children: features.map((f) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(f.$1, size: 18, color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    Text(f.$3, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
                  ],
                ),
              ),
              const Icon(LucideIcons.check, size: 16, color: Color(0xFF22C55E)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  // Trouve un package par identifier RevenueCat ($rc_annual / $rc_monthly) avec fallback sur PackageType
  Package? _findPackage(List<Package> packages, String identifier, PackageType fallbackType) {
    return packages.where((p) => p.identifier == identifier).firstOrNull
        ?? packages.where((p) => p.packageType == fallbackType).firstOrNull;
  }

  Widget _buildPlans() {
    if (_offerings?.current == null) {
      return _buildFallbackPlans();
    }

    final packages = _offerings!.current!.availablePackages;
    final yearly  = _findPackage(packages, '\$rc_annual', PackageType.annual);
    final monthly = _findPackage(packages, '\$rc_monthly', PackageType.monthly);

    return Column(
      children: [
        if (yearly != null) _buildPlanTile(
          package: yearly,
          label: 'Annuel',
          sublabel: 'Économisez 33%',
          badge: 'POPULAIRE',
          isSelected: _yearlySelected,
          onTap: () => setState(() { _yearlySelected = true; _selectedPackage = yearly; }),
        ),
        if (yearly != null && monthly != null) const SizedBox(height: 12),
        if (monthly != null) _buildPlanTile(
          package: monthly,
          label: 'Mensuel',
          isSelected: !_yearlySelected,
          onTap: () => setState(() { _yearlySelected = false; _selectedPackage = monthly; }),
        ),
      ],
    );
  }

  Widget _buildFallbackPlans() {
    return Column(
      children: [
        _buildStaticPlanTile(
          label: 'Annuel', price: '79,99€ / an', perMonth: '6,67€ / mois',
          badge: 'POPULAIRE', isSelected: _yearlySelected,
          onTap: () => setState(() { _yearlySelected = true; _selectedPackage = null; }),
        ),
        const SizedBox(height: 12),
        _buildStaticPlanTile(
          label: 'Mensuel', price: '9,99€ / mois', isSelected: !_yearlySelected,
          onTap: () => setState(() { _yearlySelected = false; _selectedPackage = null; }),
        ),
      ],
    );
  }

  Widget _buildPlanTile({
    required Package package,
    required String label,
    String? sublabel,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final price = package.storeProduct.priceString;
    final perMonth = package.packageType == PackageType.annual
        ? '≈ ${_yearlyPerMonth(package.storeProduct.price)}€ / mois'
        : null;

    return _buildStaticPlanTile(
      label: label, price: price, perMonth: perMonth,
      sublabel: sublabel, badge: badge,
      isSelected: isSelected, onTap: onTap,
    );
  }

  String _yearlyPerMonth(double yearlyPrice) {
    return (yearlyPrice / 12).toStringAsFixed(2);
  }

  Widget _buildStaticPlanTile({
    required String label,
    required String price,
    String? perMonth,
    String? sublabel,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF135BEC).withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.3),
                  width: isSelected ? 6 : 2,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label, style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white,
                      )),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(badge, style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black,
                          )),
                        ),
                      ],
                    ],
                  ),
                  if (sublabel != null)
                    Text(sublabel, style: GoogleFonts.inter(
                      fontSize: 12, color: const Color(0xFF22C55E),
                    )),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(price, style: GoogleFonts.inter(
                  fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                if (perMonth != null)
                  Text(perMonth, style: GoogleFonts.inter(
                    fontSize: 11, color: Colors.white.withValues(alpha: 0.4),
                  )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCTA() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF135BEC), Color(0xFF38BDF8)],
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF135BEC).withValues(alpha: 0.4),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _purchasing ? null : _purchase,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _purchasing
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(
                  'Commencer l\'essai gratuit 7 jours',
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
        ),
      ),
    );
  }
}
