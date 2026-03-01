import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

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
          'Statistiques & Intel',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildVulnerabilityWeather(),
            const SizedBox(height: 32),
            _buildSectionTitle("Intensité de l'actualité cyber"),
            const SizedBox(height: 16),
            _buildActivityChart(),
            const SizedBox(height: 32),
            _buildSectionTitle("Top des menaces actives"),
            const SizedBox(height: 16),
            _buildActiveThreats(),
            const SizedBox(height: 32),
            _buildSectionTitle("Secteurs d'activité les plus ciblés"),
            const SizedBox(height: 16),
            _buildTopIndustries(),
            const SizedBox(height: 32),
            _buildSectionTitle("Vecteurs d'infection initiaux"),
            const SizedBox(height: 16),
            _buildAccessVectors(),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildVulnerabilityWeather() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF135BEC), Color(0xFF38BDF8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Météo des Vulnérabilités (CVEs)",
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(LucideIcons.cloudLightning, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "42",
            style: GoogleFonts.libreBaskerville(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Nouvelles vulnérabilités critiques (CVSS > 9.0) cette semaine",
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final heights = [0.4, 0.7, 0.5, 0.9, 0.3, 0.6, 0.8];
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 24,
                height: 140 * heights[index],
                decoration: BoxDecoration(
                  color: index == 3 ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                ['L', 'M', 'M', 'J', 'V', 'S', 'D'][index],
                style: GoogleFonts.inter(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildActiveThreats() {
    final threats = ['LockBit 3.0', 'BlackCat', 'Infostealers', 'Agent Tesla'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: threats.map((threat) {
          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF38BDF8).withValues(alpha: 0.2)),
            ),
            child: Text(
              threat,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF38BDF8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopIndustries() {
    final industries = [
      {'name': 'Santé', 'value': '34%', 'color': const Color(0xFFF87171)},
      {'name': 'Finance', 'value': '22%', 'color': const Color(0xFFFB923C)},
      {'name': 'Gouvernement', 'value': '15%', 'color': const Color(0xFFFBBF24)},
    ];

    return Column(
      children: industries.map((industry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: industry['color'] as Color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                industry['name'] as String,
                style: GoogleFonts.inter(fontSize: 16, color: Colors.white),
              ),
              const Spacer(),
              Text(
                industry['value'] as String,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: industry['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAccessVectors() {
    final vectors = [
      {'name': 'Phishing', 'value': '45%', 'icon': LucideIcons.mail},
      {'name': 'Exploitation de faille/CVE', 'value': '30%', 'icon': LucideIcons.terminal},
      {'name': 'Identifiants volés', 'value': '15%', 'icon': LucideIcons.key},
    ];

    return Column(
      children: vectors.map((vector) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.02),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(vector['icon'] as IconData, size: 20, color: const Color(0xFF38BDF8)),
              ),
              const SizedBox(width: 16),
              Text(
                vector['name'] as String,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Text(
                vector['value'] as String,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
