import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../theme/terminal_theme.dart';
import '../services/subscription_service.dart';
import '../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

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
    try {
      final offerings = await SubscriptionService.getOfferings();
      if (mounted) {
        setState(() {
          _offerings = offerings;
          _loading = false;
          if (offerings?.current != null) {
            final packages = offerings!.current!.availablePackages;
            final yearly  = _findPackage(packages, '\$rc_annual', PackageType.annual);
            final monthly = _findPackage(packages, '\$rc_monthly', PackageType.monthly);
            _selectedPackage = yearly ?? monthly;
          } else {
            _error = offerings == null
                ? 'RC: ${SubscriptionService.lastOfferingsError ?? "getOfferings() → null"}'
                : 'RC: current offering null (${offerings.all.keys.join(', ')})';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() { _loading = false; _error = 'RC error: $e'; });
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
          content: Text('Bienvenue dans Cybrief Premium !',
              style: GoogleFonts.jetBrainsMono(fontSize: 12)),
          backgroundColor: TT.green,
          behavior: SnackBarBehavior.floating,
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

  Package? _findPackage(List<Package> packages, String identifier, PackageType fallbackType) {
    return packages.where((p) => p.identifier == identifier).firstOrNull
        ?? packages.where((p) => p.packageType == fallbackType).firstOrNull;
  }

  String _yearlyPerMonth(double yearlyPrice) {
    return (yearlyPrice / 12).toStringAsFixed(2);
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          // TopBar with close
          Container(
            height: 28,
            decoration: const BoxDecoration(
              color: TT.bg,
              border: Border(bottom: BorderSide(color: TT.line, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text('// CYBRIEF / PRO',
                      style: TT.mono(size: 10, letterSpacing: 0.5)),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text('× CLOSE',
                      style: TT.mono(size: 10, color: TT.muted)),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 20, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('\$ ./upgrade --pro',
                            style: TT.mono(
                                size: 10, color: TT.accent, letterSpacing: 1)),
                        const SizedBox(height: 8),
                        RichText(
                          text: TextSpan(
                            style: TT.sans(
                                size: 30,
                                weight: FontWeight.w800,
                                color: TT.text,
                                letterSpacing: -1,
                                height: 1.05),
                            children: [
                              const TextSpan(text: 'Tu es à '),
                              TextSpan(
                                text: '2 menaces',
                                style: TT.sans(
                                    size: 30,
                                    weight: FontWeight.w800,
                                    color: TT.accent,
                                    letterSpacing: -1),
                              ),
                              const TextSpan(text: '\nde manquer un breach.'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Quota gratuit: 5 briefs/jour. Critiques bloquées hors heures ouvrées.',
                          style: TT.sans(size: 13, color: TT.muted, height: 1.45),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Feature table
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: TT.line, width: 1),
                    ),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          color: TT.surface,
                          child: Row(children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Text('FEATURE',
                                    style: TT.mono(
                                        size: 9, letterSpacing: 1)),
                              ),
                            ),
                            Container(
                              width: 70,
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        color: TT.line, width: 1))),
                              child: Text('FREE',
                                  textAlign: TextAlign.center,
                                  style: TT.mono(
                                      size: 9, letterSpacing: 1)),
                            ),
                            Container(
                              width: 70,
                              padding: const EdgeInsets.all(10),
                              decoration: const BoxDecoration(
                                border: Border(
                                    left: BorderSide(
                                        color: TT.line, width: 1))),
                              child: Text('PRO',
                                  textAlign: TextAlign.center,
                                  style: TT.mono(
                                      size: 9,
                                      weight: FontWeight.w700,
                                      color: TT.accent,
                                      letterSpacing: 1)),
                            ),
                          ]),
                        ),
                        ...[
                          ('Articles/jour', '5', '∞'),
                          ('Alertes push', 'CRIT', 'TOUTES'),
                          ('CVE complets', '○', '●'),
                          ('Threat Intel', '○', '●'),
                          ('Newsletter', '○', '●'),
                          ('Export STIX', '○', '●'),
                        ].asMap().entries.map((e) {
                          final last = e.key == 5;
                          final r = e.value;
                          return Container(
                            decoration: BoxDecoration(
                              border: Border(
                                top: const BorderSide(
                                    color: TT.line, width: 1),
                                bottom: last
                                    ? BorderSide.none
                                    : BorderSide.none,
                              ),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 11, vertical: 10),
                                  child: Text(r.$1,
                                      style: TT.sans(
                                          size: 12, color: TT.text)),
                                ),
                              ),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      left: BorderSide(
                                          color: TT.line, width: 1))),
                                child: Text(r.$2,
                                    textAlign: TextAlign.center,
                                    style: TT.mono(
                                        size: 11, color: TT.muted)),
                              ),
                              Container(
                                width: 70,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 11, vertical: 10),
                                decoration: const BoxDecoration(
                                  border: Border(
                                      left: BorderSide(
                                          color: TT.line, width: 1))),
                                child: Text(r.$3,
                                    textAlign: TextAlign.center,
                                    style: TT.mono(
                                        size: 11,
                                        weight: FontWeight.w700,
                                        color: TT.accent)),
                              ),
                            ]),
                          );
                        }),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Plans
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: _loading
                        ? const Center(
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    color: TT.accent, strokeWidth: 1.5)))
                        : _buildPlans(),
                  ),

                  const SizedBox(height: 14),

                  // CTA
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GestureDetector(
                      onTap: _purchasing ? null : _purchase,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        color: TT.accent,
                        child: Center(
                          child: _purchasing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      color: Colors.black, strokeWidth: 2))
                              : Text('ESSAI 7 JOURS · GRATUIT →',
                                  style: TT.mono(
                                      size: 12,
                                      weight: FontWeight.w700,
                                      color: TT.bg,
                                      letterSpacing: 1)),
                        ),
                      ),
                    ),
                  ),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Text(_error!,
                          style: TT.sans(size: 12, color: TT.red)),
                    ),

                  const SizedBox(height: 8),
                  Center(
                    child: GestureDetector(
                      onTap: _purchasing ? null : _restore,
                      child: Text('RESTAURER MES ACHATS',
                          style: TT.mono(size: 10, color: TT.muted,
                              letterSpacing: 0.5)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: Text(
                      'SANS ENGAGEMENT · ANNULE QUAND TU VEUX',
                      style: TT.mono(size: 9, letterSpacing: 0.5),
                    ),
                  ),

                  const SizedBox(height: 12),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        GestureDetector(
                          onTap: () => _openUrl('https://cybrief-landing.vercel.app/privacy'),
                          child: Text('Confidentialité',
                              style: TT.mono(size: 9, color: TT.accent, letterSpacing: 0.5)),
                        ),
                        Text('   ·   ', style: TT.mono(size: 9, color: TT.muted)),
                        GestureDetector(
                          onTap: () => _openUrl('https://cybrief-landing.vercel.app/terms'),
                          child: Text('Conditions d\'utilisation',
                              style: TT.mono(size: 9, color: TT.accent, letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlans() {
    if (_offerings?.current == null) return _buildFallbackPlans();

    final packages = _offerings!.current!.availablePackages;
    final yearly  = _findPackage(packages, '\$rc_annual', PackageType.annual);
    final monthly = _findPackage(packages, '\$rc_monthly', PackageType.monthly);

    return Column(children: [
      if (yearly != null)
        _buildPlanTile(
          label: 'ANNUEL',
          price: yearly.storeProduct.priceString,
          perMonth: '≈ ${_yearlyPerMonth(yearly.storeProduct.price)}€/mois',
          badge: '-33%',
          isSelected: _yearlySelected,
          onTap: () => setState(() { _yearlySelected = true; _selectedPackage = yearly; }),
        ),
      if (yearly != null && monthly != null) const SizedBox(height: 8),
      if (monthly != null)
        _buildPlanTile(
          label: 'MENSUEL',
          price: monthly.storeProduct.priceString,
          isSelected: !_yearlySelected,
          onTap: () => setState(() { _yearlySelected = false; _selectedPackage = monthly; }),
        ),
    ]);
  }

  Widget _buildFallbackPlans() {
    return Column(children: [
      _buildPlanTile(
        label: 'ANNUEL',
        price: '79,99€/an',
        perMonth: '6,67€/mois',
        badge: '-33%',
        isSelected: _yearlySelected,
        onTap: () => setState(() { _yearlySelected = true; _selectedPackage = null; }),
      ),
      const SizedBox(height: 8),
      _buildPlanTile(
        label: 'MENSUEL',
        price: '9,99€/mois',
        isSelected: !_yearlySelected,
        onTap: () => setState(() { _yearlySelected = false; _selectedPackage = null; }),
      ),
    ]);
  }

  Widget _buildPlanTile({
    required String label,
    required String price,
    String? perMonth,
    String? badge,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? TT.accent : TT.line,
                width: isSelected ? 1 : 1,
              ),
              color: isSelected ? TT.accent.withOpacity(0.08) : Colors.transparent,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(label,
                    style: TT.mono(
                        size: 11,
                        color: isSelected ? TT.accent : TT.muted,
                        letterSpacing: 1)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(price,
                        style: TT.sans(
                            size: isSelected ? 22 : 18,
                            weight: FontWeight.w800,
                            color: TT.text)),
                    if (perMonth != null)
                      Text(perMonth,
                          style: TT.mono(size: 10, color: TT.muted)),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null && isSelected)
            Positioned(
              top: -8, right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                color: TT.accent,
                child: Text(badge,
                    style: TT.mono(
                        size: 9,
                        weight: FontWeight.w700,
                        color: TT.bg,
                        letterSpacing: 1)),
              ),
            ),
        ],
      ),
    );
  }
}
