import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _notifCritique = true;
  bool _notifEleve = true;
  bool _notifMoyen = false;
  bool _twoFactor = true;
  bool _darkMode = true;

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
              _buildNavRow(LucideIcons.user, 'Modifier le profil', null, onTap: _showEditProfile),
              _buildDivider(),
              _buildNavRow(LucideIcons.mail, 'E-mail', 'utilisateur@cybrief.fr'),
              _buildDivider(),
              _buildNavRow(LucideIcons.logIn, 'Connexion / Inscription', null,
                  onTap: () => Navigator.pushNamed(context, '/login')),
            ]),
            const SizedBox(height: 24),

            // ── Sécurité ─────────────────────────────────────────
            _buildSectionHeader('SÉCURITÉ'),
            _buildCard([
              _buildNavRow(LucideIcons.keyRound, 'Changer le mot de passe', null, onTap: _showChangePassword),
              _buildDivider(),
              _buildToggle(LucideIcons.shieldCheck, 'Double authentification', _twoFactor,
                  const Color(0xFF22C55E), (v) => setState(() => _twoFactor = v)),
            ]),
            const SizedBox(height: 24),

            // ── Notifications ────────────────────────────────────
            _buildSectionHeader('NOTIFICATIONS'),
            _buildCard([
              _buildToggle(LucideIcons.octagonAlert, 'Alertes CRITIQUES', _notifCritique,
                  const Color(0xFFEF4444), (v) => setState(() => _notifCritique = v)),
              _buildDivider(),
              _buildToggle(LucideIcons.triangleAlert, 'Alertes ÉLEVÉES', _notifEleve,
                  const Color(0xFFF97316), (v) => setState(() => _notifEleve = v)),
              _buildDivider(),
              _buildToggle(LucideIcons.bell, 'Alertes MOYENNES', _notifMoyen,
                  const Color(0xFFFBBF24), (v) => setState(() => _notifMoyen = v)),
            ]),
            const SizedBox(height: 24),

            // ── Affichage ────────────────────────────────────────
            _buildSectionHeader('AFFICHAGE'),
            _buildCard([
              _buildToggle(LucideIcons.moon, 'Mode sombre', _darkMode,
                  const Color(0xFF38BDF8), (v) => setState(() => _darkMode = v)),
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

            // ── Déconnexion ──────────────────────────────────────
            _buildLogoutButton(),
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
                    color: const Color(0xFF22C55E),
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
                Text('Utilisateur Cybrief', style: GoogleFonts.inter(
                  fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white,
                )),
                const SizedBox(height: 2),
                Text('utilisateur@cybrief.fr', style: GoogleFonts.inter(
                  fontSize: 13, color: Colors.white.withValues(alpha: 0.5),
                )),
              ],
            ),
          ),
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
        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
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
              Text('Modifier le profil', style: GoogleFonts.inter(
                fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white,
              )),
              const SizedBox(height: 20),
              _buildTextField('Nom complet', 'Utilisateur Cybrief', LucideIcons.user),
              const SizedBox(height: 14),
              _buildTextField('E-mail', 'utilisateur@cybrief.fr', LucideIcons.mail),
              const SizedBox(height: 14),
              _buildTextField('Entreprise', 'Mon Entreprise', LucideIcons.building2),
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
                  child: Text('Sauvegarder', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String hint, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(
          fontSize: 12, fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.5), letterSpacing: 0.8,
        )),
        const SizedBox(height: 8),
        TextField(
          style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(icon, size: 18, color: const Color(0xFF38BDF8)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
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
              _buildTextField('Mot de passe actuel', '••••••••••', LucideIcons.lock),
              const SizedBox(height: 14),
              _buildTextField('Nouveau mot de passe', '••••••••••', LucideIcons.lockOpen),
              const SizedBox(height: 14),
              _buildTextField('Confirmer le mot de passe', '••••••••••', LucideIcons.shieldCheck),
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
