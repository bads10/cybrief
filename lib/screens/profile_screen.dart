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
  bool _darkMode = true;
  bool _autoPublish = false;

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
            // App info card
            _buildAppCard(),
            const SizedBox(height: 28),

            _buildSectionHeader('NOTIFICATIONS'),
            _buildCard([
              _buildToggle(LucideIcons.octagonAlert, 'Alertes CRITIQUES', _notifCritique, const Color(0xFFEF4444),
                (v) => setState(() => _notifCritique = v)),
              _buildDivider(),
              _buildToggle(LucideIcons.triangleAlert, 'Alertes ÉLEVÉES', _notifEleve, const Color(0xFFF97316),
                (v) => setState(() => _notifEleve = v)),
              _buildDivider(),
              _buildToggle(LucideIcons.bell, 'Alertes MOYENNES', _notifMoyen, const Color(0xFFFBBF24),
                (v) => setState(() => _notifMoyen = v)),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('AFFICHAGE'),
            _buildCard([
              _buildToggle(LucideIcons.moon, 'Mode sombre', _darkMode, const Color(0xFF38BDF8),
                (v) => setState(() => _darkMode = v)),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('FLUX RSS'),
            _buildCard([
              _buildNavRow(LucideIcons.rss, 'Sources actives', '29 sources', '/categories'),
              _buildDivider(),
              _buildToggle(LucideIcons.zap, 'Publication automatique', _autoPublish, const Color(0xFF22C55E),
                (v) => setState(() => _autoPublish = v)),
            ]),

            const SizedBox(height: 24),
            _buildSectionHeader('À PROPOS'),
            _buildCard([
              _buildInfoRow(LucideIcons.info, 'Version', '1.0.0'),
              _buildDivider(),
              _buildInfoRow(LucideIcons.server, 'Backend', 'Railway · Production'),
              _buildDivider(),
              _buildInfoRow(LucideIcons.cpu, 'IA', 'Google Gemini 1.5 Flash'),
            ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildAppCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF135BEC).withValues(alpha: 0.3),
            const Color(0xFF38BDF8).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.3)),
            ),
            child: const Icon(LucideIcons.shield, color: Color(0xFF38BDF8), size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cybrief', style: GoogleFonts.libreBaskerville(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white,
              )),
              Text('Intelligence Cyber Quotidienne', style: GoogleFonts.inter(
                fontSize: 12, color: Colors.white.withValues(alpha: 0.6),
              )),
            ],
          ),
        ],
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

  Widget _buildDivider() => Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 52);

  Widget _buildToggle(IconData icon, String label, bool value, Color color, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
        ))),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: const Color(0xFF38BDF8),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ]),
    );
  }

  Widget _buildNavRow(IconData icon, String label, String subtitle, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(LucideIcons.rss, size: 18, color: Color(0xFF38BDF8)),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: GoogleFonts.inter(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
          ))),
          Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
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
          child: Icon(icon, size: 18, color: Colors.white.withValues(alpha: 0.5)),
        ),
        const SizedBox(width: 14),
        Expanded(child: Text(label, style: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withValues(alpha: 0.9),
        ))),
        Text(value, style: GoogleFonts.inter(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
      ]),
    );
  }
}
