import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifCritique = true;
  bool _notifEleve    = true;
  bool _notifMoyen    = false;
  bool _darkMode      = true;
  String _newsletterFreq = 'off';
  String _currentLang = 'fr';

  @override
  void initState() {
    super.initState();
    _loadUserPrefs();
  }

  Future<void> _loadUserPrefs() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await UserService.getUser(uid);
    if (user != null && mounted) {
      setState(() {
        _notifCritique = user['notifCritical'] as bool? ?? true;
        _notifEleve    = user['notifHigh']     as bool? ?? true;
        _notifMoyen    = user['notifMedium']   as bool? ?? false;
        _newsletterFreq = user['newsletterSubscribed'] == true
            ? (user['newsletterFrequency'] as String? ?? 'daily')
            : 'off';
        _currentLang = user['language'] as String? ?? 'fr';
      });
    }
  }

  String _newsletterFreqLabel() {
    switch (_newsletterFreq) {
      case 'daily':  return 'Quotidien';
      case 'weekly': return 'Hebdomadaire';
      default:       return 'Désactivé';
    }
  }

  void _toggleLanguage() {
    final newLang = _currentLang == 'fr' ? 'en' : 'fr';
    setState(() => _currentLang = newLang);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) UserService.updateUser(uid, {'language': newLang});
    // Changer la locale de l'app
    // CybriefApp.of(context)?.setLocale(Locale(newLang));
  }

  void _showNewsletterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2),
            ))),
            const SizedBox(height: 24),
            Text('Newsletter', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 20),
            for (final freq in ['daily', 'weekly', 'off'])
              _buildFreqOption(freq),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqOption(String freq) {
    final labels = {'daily': 'Quotidien (18h30)', 'weekly': 'Hebdomadaire (lundi)', 'off': 'Désactivé'};
    final isSelected = _newsletterFreq == freq;
    return GestureDetector(
      onTap: () async {
        setState(() => _newsletterFreq = freq);
        Navigator.pop(context);
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid == null) return;
        if (freq == 'off') {
          await UserService.unsubscribeNewsletter(uid);
        } else {
          await UserService.subscribeNewsletter(uid, frequency: freq, language: _currentLang);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF38BDF8).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.07)),
        ),
        child: Row(
          children: [
            Expanded(child: Text(labels[freq]!, style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal))),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: Color(0xFF38BDF8), size: 20),
          ],
        ),
      ),
    );
  }

  // ── Données utilisateur depuis Firebase Auth ─────────────────────────────
  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Visiteur';
    final name = user.displayName;
    if (name != null && name.isNotEmpty) return name;
    return user.email?.split('@').first ?? 'Utilisateur';
  }

  String get _displayEmail {
    return FirebaseAuth.instance.currentUser?.email ?? 'Non connecté';
  }

  bool get _isLoggedIn => FirebaseAuth.instance.currentUser != null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('PARAMÈTRES', style: GoogleFonts.inter(
          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white, letterSpacing: 1.5,
        )),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profil utilisateur ──────────────────────────────
            _buildProfileCard(),
            const SizedBox(height: 20),

            // ── Premium ─────────────────────────────────────────
            _buildPremiumBanner(),
            const SizedBox(height: 28),

            // ── Compte ──────────────────────────────────────────
            _buildSectionHeader('COMPTE'),
            _buildCard([
              if (_isLoggedIn) ...[
                _buildNavRow(LucideIcons.user, 'Modifier le profil', null, onTap: _showEditProfile),
                _buildDivider(),
                _buildNavRow(LucideIcons.mail, 'E-mail', _displayEmail),
                _buildDivider(),
                _buildNavRow(LucideIcons.keyRound, 'Changer le mot de passe', null, onTap: _showChangePassword),
              ] else
                _buildNavRow(LucideIcons.logIn, 'Connexion / Inscription', null,
                    onTap: () => Navigator.pushNamed(context, '/login')),
            ]),
            const SizedBox(height: 24),

            // ── Notifications ────────────────────────────────────
            _buildSectionHeader('NOTIFICATIONS'),
            _buildCard([
              _buildToggle(LucideIcons.octagonAlert, 'Alertes CRITIQUES', _notifCritique,
                  const Color(0xFFEF4444), (v) => _updateNotif('critical', v)),
              _buildDivider(),
              _buildToggle(LucideIcons.triangleAlert, 'Alertes ÉLEVÉES', _notifEleve,
                  const Color(0xFFF97316), (v) => _updateNotif('high', v)),
              _buildDivider(),
              _buildToggle(LucideIcons.bell, 'Alertes MOYENNES', _notifMoyen,
                  const Color(0xFFFBBF24), (v) => _updateNotif('medium', v)),
            ]),
            const SizedBox(height: 24),

            // ── Affichage ────────────────────────────────────────
            _buildSectionHeader('AFFICHAGE'),
            _buildCard([
              _buildToggle(LucideIcons.moon, 'Mode sombre', _darkMode,
                  const Color(0xFF38BDF8), (v) => setState(() => _darkMode = v)),
            ]),
            const SizedBox(height: 24),

            // ── Newsletter ───────────────────────────────────────
            if (_isLoggedIn) ...[
              _buildSectionHeader('NEWSLETTER'),
              _buildCard([
                _buildNavRow(
                  LucideIcons.mail,
                  'Fréquence',
                  _newsletterFreqLabel(),
                  onTap: _showNewsletterSheet,
                ),
              ]),
              const SizedBox(height: 24),
            ],

            // ── Langue ───────────────────────────────────────────
            _buildSectionHeader('LANGUE / LANGUAGE'),
            _buildCard([
              _buildNavRow(
                LucideIcons.globe,
                'Langue de l\'app',
                _currentLang == 'en' ? '🇬🇧 English' : '🇫🇷 Français',
                onTap: _toggleLanguage,
              ),
            ]),
            const SizedBox(height: 24),

            // ── Flux RSS ─────────────────────────────────────────
            _buildSectionHeader('FLUX RSS'),
            _buildCard([
              _buildNavRow(LucideIcons.rss, 'Sources actives', '29 sources',
                  onTap: () => Navigator.pushNamed(context, '/categories')),
            ]),
            const SizedBox(height: 24),

            // ── À propos ─────────────────────────────────────────
            _buildSectionHeader('À PROPOS'),
            _buildCard([
              _buildInfoRow(LucideIcons.info, 'Version', '1.0.0'),
            ]),
            const SizedBox(height: 32),

            // ── Bouton déconnexion / connexion ───────────────────
            if (_isLoggedIn)
              _buildLogoutButton()
            else
              _buildLoginButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  // ── Widgets ────────────────────────────────────────────────────

  Widget _buildProfileCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: const Color(0xFF135BEC).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.4), width: 2),
                ),
                child: const Icon(LucideIcons.user, size: 30, color: Color(0xFF38BDF8)),
              ),
              Positioned(
                bottom: 0, right: 0,
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: _isLoggedIn ? const Color(0xFF22C55E) : Colors.grey,
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F172A), width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName, style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                const SizedBox(height: 2),
                Text(_displayEmail, style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.5),
                )),
              ],
            ),
          ),
          if (_isLoggedIn)
            GestureDetector(
              onTap: _showEditProfile,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(LucideIcons.pencil, size: 16, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => _showPremiumSheet(),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF7C3AED), Color(0xFF135BEC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
              blurRadius: 20, offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(LucideIcons.crown, color: Colors.amber, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Passer à PREMIUM', style: GoogleFonts.inter(
                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white,
                  )),
                  Text('Accès illimité · Alertes temps réel · CVE exclusifs',
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('Voir', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF7C3AED),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12, left: 2),
    child: Text(title, style: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.bold,
      color: const Color(0xFF38BDF8).withValues(alpha: 0.8), letterSpacing: 1.4,
    )),
  );

  Widget _buildCard(List<Widget> children) => Container(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
    ),
    child: Column(children: children),
  );

  Widget _buildDivider() =>
      Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 52);

  Widget _buildToggle(IconData icon, String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
        ))),
        Switch(value: value, onChanged: onChanged,
          activeColor: const Color(0xFF38BDF8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap),
      ]),
    );
  }

  Widget _buildNavRow(IconData icon, String label, String? subtitle, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
          ))),
          if (subtitle != null) Text(subtitle, style: GoogleFonts.inter(
            fontSize: 13, color: Colors.white.withValues(alpha: 0.4),
          )),
          const SizedBox(width: 6),
          Icon(LucideIcons.chevronRight, size: 16, color: Colors.white.withValues(alpha: 0.25)),
        ]),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.4)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
        ))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
      ]),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _logout,
        icon: const Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 18),
        label: Text('Se déconnecter', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFFEF4444),
        )),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, '/login'),
        icon: const Icon(LucideIcons.logIn, size: 18),
        label: Text('Se connecter', style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.bold,
        )),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF135BEC),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

  // ── Modals ──────────────────────────────────────────────────────

  void _showPremiumSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2),
            )),
            const SizedBox(height: 24),
            const Icon(LucideIcons.crown, color: Colors.amber, size: 48),
            const SizedBox(height: 16),
            Text('Cybrief PREMIUM', style: GoogleFonts.inter(
              fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white,
            )),
            const SizedBox(height: 8),
            Text('Intelligence cyber sans limites', style: GoogleFonts.inter(
              fontSize: 14, color: Colors.white.withValues(alpha: 0.5),
            )),
            const SizedBox(height: 28),
            _premiumFeature(LucideIcons.zap, 'Alertes temps réel', 'Notifié instantanément'),
            _premiumFeature(LucideIcons.shieldAlert, 'CVE exclusifs', 'Base complète NVD + CISA'),
            _premiumFeature(LucideIcons.fileText, 'Rapports détaillés', 'Analyses approfondies'),
            _premiumFeature(LucideIcons.rss, 'Sources illimitées', 'Toutes les sources actives'),
            const SizedBox(height: 28),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF135BEC)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Text('9,99 € / mois', style: GoogleFonts.inter(
                  fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                Text('ou 79,99 € / an — économisez 33%', style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.7),
                )),
              ]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Commencer l\'essai gratuit 7 jours', style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, fontSize: 15,
                )),
              ),
            ),
            const SizedBox(height: 10),
            Text('Sans engagement · Annulable à tout moment', style: GoogleFonts.inter(
              fontSize: 12, color: Colors.white.withValues(alpha: 0.35),
            )),
          ],
        ),
      ),
    );
  }

  Widget _premiumFeature(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.amber),
        ),
        const SizedBox(width: 14),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.white.withValues(alpha: 0.45))),
        ]),
        const Spacer(),
        const Icon(LucideIcons.check, size: 18, color: Colors.amber),
      ]),
    );
  }

  void _showEditProfile() {
    final nameCtrl = TextEditingController(text: _displayName);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2),
                ))),
                const SizedBox(height: 24),
                Text('Modifier le profil', style: GoogleFonts.inter(
                  fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                const SizedBox(height: 20),
                _buildModalTextField('Nom complet', _displayName, LucideIcons.user, controller: nameCtrl),
                const SizedBox(height: 14),
                _buildModalTextField('E-mail', _displayEmail, LucideIcons.mail, readOnly: true),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: saving ? null : () async {
                      setModalState(() => saving = true);
                      final newName = nameCtrl.text.trim();
                      if (newName.isNotEmpty && newName != _displayName) {
                        await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        if (uid != null) {
                          await UserService.updateUser(uid, {'displayName': newName});
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                        : Text('Sauvegarder', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _updateNotif(String type, bool value) {
    setState(() {
      if (type == 'critical') _notifCritique = value;
      if (type == 'high') _notifEleve = value;
      if (type == 'medium') _notifMoyen = value;
    });
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = <String, dynamic>{};
    if (type == 'critical') data['notifCritical'] = value;
    if (type == 'high') data['notifHigh'] = value;
    if (type == 'medium') data['notifMedium'] = value;
    UserService.updateUser(uid, data);
  }

  Widget _buildModalTextField(String label, String hint, IconData? icon, {TextEditingController? controller, bool readOnly = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          style: GoogleFonts.inter(color: readOnly ? Colors.white.withValues(alpha: 0.4) : Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: icon != null ? Icon(icon, size: 18, color: const Color(0xFF38BDF8)) : null,
            filled: true,
            fillColor: Colors.white.withValues(alpha: readOnly ? 0.02 : 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF38BDF8)),
            ),
          ),
        ),
      ],
    );
  }

  void _showChangePassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(2),
              ))),
              const SizedBox(height: 24),
              Text('Changer le mot de passe', style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
              )),
              const SizedBox(height: 20),
              _buildModalTextField('Mot de passe actuel', '••••••••••', LucideIcons.lock),
              const SizedBox(height: 14),
              _buildModalTextField('Nouveau mot de passe', '••••••••••', LucideIcons.lockOpen),
              const SizedBox(height: 14),
              _buildModalTextField('Confirmer le mot de passe', '••••••••••', LucideIcons.shieldCheck),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38BDF8),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Mettre à jour', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
