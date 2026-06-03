import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../widgets/terminal_widgets.dart';
import '../theme/terminal_theme.dart';
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
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/');
  }

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

  String get _initials {
    final n = _displayName;
    final parts = n.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return n.isNotEmpty ? n[0].toUpperCase() : '?';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TT.bg,
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top),
          const TerminalTopBar(label: 'PARAMÈTRES', right: ''),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserCard(),
                  if (!_isLoggedIn) _buildLoginCta(),
                  _buildPremiumBanner(),
                  _buildSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildUserCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: TT.line, width: 1),
        color: TT.surface,
      ),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: TT.accent.withOpacity(0.15),
              border: Border.all(color: TT.accent.withOpacity(0.5), width: 1),
            ),
            child: Center(
              child: Text(_initials,
                  style: TT.sans(
                      size: 18, weight: FontWeight.w800, color: TT.accent)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_displayName,
                    style: TT.sans(
                        size: 15, weight: FontWeight.w700, color: TT.text)),
                const SizedBox(height: 2),
                Text(_displayEmail,
                    style: TT.mono(size: 10, color: TT.muted)),
                const SizedBox(height: 6),
                Row(children: [
                  _badge('FREE', TT.muted),
                  const SizedBox(width: 6),
                  _badge('STREAK 0d', TT.line),
                ]),
              ],
            ),
          ),
          if (_isLoggedIn)
            GestureDetector(
              onTap: _showEditProfile,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Text('EDIT',
                    style: TT.mono(
                      size: 10,
                      weight: FontWeight.w700,
                      color: TT.accent,
                      letterSpacing: 1,
                    )),
              ),
            ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Text(label,
          style: TT.mono(size: 9, color: TT.muted, letterSpacing: 0.5)),
    );
  }

  Widget _buildLoginCta() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/login'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        padding: const EdgeInsets.symmetric(vertical: 11),
        color: TT.text,
        child: Center(
          child: Text('SE CONNECTER',
              style: TT.mono(
                  size: 11,
                  weight: FontWeight.w700,
                  color: TT.bg,
                  letterSpacing: 1)),
        ),
      ),
    );
  }

  Widget _buildPremiumBanner() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/subscribe'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: TT.accent, width: 1),
          color: TT.accent.withOpacity(0.06),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('// CYBRIEF / PRO',
                style: TT.mono(
                    size: 10,
                    weight: FontWeight.w700,
                    color: TT.accent,
                    letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Text('Accès illimité · 6.67€/mois',
                style: TT.sans(
                    size: 18, weight: FontWeight.w700, color: TT.text)),
            const SizedBox(height: 4),
            Text('Alertes temps réel · CVE complets · Threat Intel',
                style: TT.sans(size: 12, color: TT.muted)),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              color: TT.accent,
              child: Center(
                child: Text('UPGRADE →',
                    style: TT.mono(
                        size: 11,
                        weight: FontWeight.w700,
                        color: TT.bg,
                        letterSpacing: 1)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
          child: Text('// CONFIG',
              style: TT.mono(
                  size: 10, color: TT.muted, letterSpacing: 1)),
        ),
        ...[
          _SettingsRow(
            label: 'NOTIFICATIONS',
            value:
                '${[_notifCritique, _notifEleve, _notifMoyen].where((b) => b).length} actives',
            onTap: () => Navigator.pushNamed(context, '/notifications'),
          ),
          _SettingsRow(
            label: 'NEWSLETTER',
            value: _newsletterFreqLabel().toUpperCase(),
            onTap: _showNewsletterSheet,
          ),
          _SettingsRow(
            label: 'LANGUE',
            value: _currentLang.toUpperCase(),
            onTap: _toggleLanguage,
          ),
          _SettingsRow(
            label: 'SOURCES',
            value: '29 actives',
            onTap: () => Navigator.pushNamed(context, '/categories'),
          ),
          _SettingsRow(
            label: 'VERSION',
            value: '1.0.0',
          ),
          _SettingsRow(
            label: 'CGU / CONFIDENTIALITÉ',
            value: '',
            onTap: () => Navigator.pushNamed(context, '/legal'),
          ),
          if (_isLoggedIn)
            _SettingsRow(
              label: 'DÉCONNEXION',
              value: '',
              labelColor: TT.red,
              onTap: _logout,
            )
          else
            _SettingsRow(
              label: 'SE CONNECTER',
              value: '',
              labelColor: TT.accent,
              onTap: () => Navigator.pushNamed(context, '/login'),
            ),
        ],
      ],
    );
  }

  void _showNewsletterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        color: TT.surface,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('// EMAIL · FRÉQUENCE',
                style: TT.mono(
                    size: 10, color: TT.muted, letterSpacing: 1.5)),
            const SizedBox(height: 16),
            for (final freq in ['daily', 'weekly', 'off'])
              _buildFreqOption(freq),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqOption(String freq) {
    final labels = {
      'daily':  'QUOTIDIEN (18h30)',
      'weekly': 'HEBDOMADAIRE (LUNDI)',
      'off':    'DÉSACTIVÉ',
    };
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
          await UserService.subscribeNewsletter(uid,
              frequency: freq, language: _currentLang);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: isSelected ? TT.accent : TT.line, width: 1),
          color: isSelected ? TT.accent.withOpacity(0.08) : Colors.transparent,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(labels[freq]!,
                  style: TT.mono(
                      size: 11,
                      weight: isSelected ? FontWeight.w700 : FontWeight.w400,
                      color: isSelected ? TT.accent : TT.text,
                      letterSpacing: 0.5)),
            ),
            if (isSelected)
              const Icon(Icons.check, size: 14, color: TT.accent),
          ],
        ),
      ),
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
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom),
          child: Container(
            color: TT.surface,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('// MODIFIER PROFIL',
                    style: TT.mono(
                        size: 10, color: TT.muted, letterSpacing: 1.5)),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  style: TT.sans(size: 15, color: TT.text),
                  decoration: InputDecoration(
                    hintText: 'Nom complet',
                    hintStyle: TT.sans(size: 15, color: TT.muted),
                    filled: true,
                    fillColor: TT.line,
                    border: OutlineInputBorder(
                        borderSide: BorderSide(color: TT.line)),
                    enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: TT.line)),
                    focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: TT.accent)),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: saving
                      ? null
                      : () async {
                          setModalState(() => saving = true);
                          final newName = nameCtrl.text.trim();
                          if (newName.isNotEmpty &&
                              newName != _displayName) {
                            await FirebaseAuth.instance.currentUser
                                ?.updateDisplayName(newName);
                            final uid =
                                FirebaseAuth.instance.currentUser?.uid;
                            if (uid != null) {
                              await UserService.updateUser(
                                  uid, {'displayName': newName});
                            }
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) setState(() {});
                        },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    color: TT.accent,
                    child: Center(
                      child: saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.black, strokeWidth: 2))
                          : Text('SAUVEGARDER',
                              style: TT.mono(
                                  size: 11,
                                  weight: FontWeight.w700,
                                  color: TT.bg,
                                  letterSpacing: 1)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.label,
    required this.value,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: TT.line, width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TT.mono(
                    size: 12,
                    weight: FontWeight.w500,
                    color: labelColor ?? TT.text)),
            Row(children: [
              Text(value, style: TT.mono(size: 11, color: TT.muted)),
              const SizedBox(width: 8),
              if (onTap != null)
                Text('›',
                    style: TT.mono(size: 14, color: TT.muted)),
            ]),
          ],
        ),
      ),
    );
  }
}
