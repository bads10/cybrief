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
  bool _twoFactorEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pushReplacementNamed(context, '/feed'),
        ),
        title: Text(
          'Profil Utilisateur',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Center(
              child: Column(
                children: [
                   Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF135BEC).withValues(alpha: 0.3), width: 2),
                    ),
                    child: const Icon(LucideIcons.user, size: 40, color: Color(0xFF135BEC)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Jean-Sébastien Laurent',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            _buildSectionHeader('INFORMATIONS PERSONNELLES'),
            _buildInfoCard([
              _buildInfoRow(LucideIcons.user, 'Nom', 'J. Laurent'),
              _buildInfoRow(LucideIcons.mail, 'E-mail', 'js.laurent@cyberbrief.fr'),
              _buildInfoRow(LucideIcons.building, 'Entreprise', 'Cybrief SAS'),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('ABONNEMENT & FACTURATION'),
            _buildInfoCard([
              _buildInfoRow(LucideIcons.award, 'Type de compte', 'PREMIUM', isBadge: true),
              _buildInfoRow(LucideIcons.creditCard, 'Gérer l\'abonnement', null),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('SÉCURITÉ'),
            _buildInfoCard([
              _buildInfoRow(LucideIcons.rotateCcw, 'Changer le mot de passe', null),
              _buildToggleRow(LucideIcons.shieldCheck, 'Double authentification', _twoFactorEnabled),
            ]),
            const SizedBox(height: 32),
            _buildSectionHeader('PRÉFÉRENCES'),
            _buildInfoCard([
              _buildNavigationRow(LucideIcons.bell, 'Notifications', '/notifications'),
              _buildNavigationRow(LucideIcons.layers, 'Catégories suivies', '/categories'),
            ]),
            const SizedBox(height: 40),
            _buildLogoutButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF38BDF8).withValues(alpha: 0.8),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          int idx = entry.key;
          Widget child = entry.value;
          if (idx == children.length - 1) return child;
          return Column(
            children: [
              child,
              Divider(height: 1, color: Colors.white.withValues(alpha: 0.05), indent: 50),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String? value, {bool isBadge = false}) {
    return InkWell(
      onTap: () {
        if (label == 'E-mail') {
           // Maybe edit email?
        } else if (label == 'Gérer l\'abonnement') {
           // Subscription flow
        } else if (label == 'Changer le mot de passe') {
           // Password flow
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (value != null)
              isBadge
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF135BEC).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF38BDF8),
                      ),
                    ),
                  )
                : Text(
                    value,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
            const SizedBox(width: 8),
            Icon(LucideIcons.chevronRight, size: 16, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow(IconData icon, String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: (val) => setState(() => _twoFactorEnabled = val),
            activeColor: const Color(0xFF38BDF8),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationRow(IconData icon, String label, String route) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF38BDF8)),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(LucideIcons.chevronRight, size: 16, color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: () => Navigator.pushReplacementNamed(context, '/'),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFEF4444), width: 1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.logOut, color: Color(0xFFEF4444), size: 18),
            const SizedBox(width: 12),
            Text(
              'Se déconnecter',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
