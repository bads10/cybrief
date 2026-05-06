import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/auth_service.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _receiveDaily  = true;
  bool _loading       = false;
  bool _loadingGoogle = false;
  bool _showPassword  = false;
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  int get _passwordStrength {
    final p = _passwordCtrl.text;
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8)                          score++;
    if (p.contains(RegExp(r'[A-Z]')))           score++;
    if (p.contains(RegExp(r'[0-9]')))           score++;
    if (p.contains(RegExp(r'[!@#\$&*~%^()_]'))) score++;
    return score;
  }

  String get _strengthLabel {
    switch (_passwordStrength) {
      case 0: return '';
      case 1: return 'Faible';
      case 2: return 'Moyen';
      case 3: return 'Fort';
      default: return 'Très fort';
    }
  }

  Color get _strengthColor {
    switch (_passwordStrength) {
      case 1: return const Color(0xFFEF4444);
      case 2: return const Color(0xFFFBBF24);
      case 3: return const Color(0xFF22C55E);
      default: return const Color(0xFF38BDF8);
    }
  }

  Future<void> _signup() async {
    final name     = _nameCtrl.text.trim();
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Le mot de passe doit contenir au moins 6 caractères.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.signUp(
      email: email,
      password: password,
      fullName: name,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compte créé ! Vérifie ton email pour confirmer ton inscription.',
            style: GoogleFonts.inter(),
          ),
          backgroundColor: const Color(0xFF22C55E),
          duration: const Duration(seconds: 5),
        ),
      );
      Navigator.pushReplacementNamed(context, '/flux');
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _signupWithGoogle() async {
    setState(() { _loadingGoogle = true; _error = null; });

    final result = await AuthService.signInWithGoogle();

    if (!mounted) return;
    setState(() => _loadingGoogle = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/flux');
    } else {
      setState(() => _error = result.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Rejoignez Cybrief',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Obtenez des résumés quotidiens concis sur les cybermenaces, directement sur votre appareil.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // ── Bouton Google ─────────────────────────────────────────────
              _buildGoogleButton(),
              const SizedBox(height: 24),

              // ── Séparateur ────────────────────────────────────────────────
              _buildDivider(),
              const SizedBox(height: 24),

              // ── Nom complet ──────────────────────────────────────────────
              _buildFieldLabel('Nom complet'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameCtrl,
                hint: 'Ex: Jean Dupont',
                isPassword: false,
                keyboardType: TextInputType.name,
              ),
              const SizedBox(height: 24),

              // ── Email ────────────────────────────────────────────────────
              _buildFieldLabel('E-mail professionnel'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailCtrl,
                hint: 'nom@entreprise.com',
                isPassword: false,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 24),

              // ── Mot de passe ─────────────────────────────────────────────
              _buildFieldLabel('Mot de passe'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordCtrl,
                hint: 'Min. 6 caractères',
                isPassword: !_showPassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              if (_passwordCtrl.text.isNotEmpty) _buildPasswordStrength(),
              const SizedBox(height: 24),

              // ── Checkbox résumé quotidien ────────────────────────────────
              Row(
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: _receiveDaily,
                      onChanged: (val) => setState(() => _receiveDaily = val!),
                      activeColor: const Color(0xFF135BEC),
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Recevoir le résumé quotidien des menaces par e-mail.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.circleAlert,
                          size: 16, color: Color(0xFFEF4444)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // ── Bouton inscription ───────────────────────────────────────
              ElevatedButton(
                onPressed: _loading ? null : _signup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF135BEC),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Créer mon compte',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Icon(LucideIcons.chevronRight, size: 20),
                        ],
                      ),
              ),
              const SizedBox(height: 32),

              // ── CGU ──────────────────────────────────────────────────────
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.5),
                        height: 1.5,
                      ),
                      children: [
                        const TextSpan(text: 'En vous inscrivant, vous acceptez nos '),
                        TextSpan(
                          text: 'Conditions d\'utilisation',
                          style: TextStyle(color: const Color(0xFF135BEC).withValues(alpha: 0.8)),
                        ),
                        const TextSpan(text: ' et notre '),
                        TextSpan(
                          text: 'Politique de confidentialité',
                          style: TextStyle(color: const Color(0xFF135BEC).withValues(alpha: 0.8)),
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: (_loading || _loadingGoogle) ? null : _signupWithGoogle,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white.withValues(alpha: 0.03),
      ),
      child: _loadingGoogle
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(text: 'G', style: TextStyle(color: Color(0xFF4285F4))),
                      TextSpan(text: 'o', style: TextStyle(color: Color(0xFFEA4335))),
                      TextSpan(text: 'o', style: TextStyle(color: Color(0xFFFBBC05))),
                      TextSpan(text: 'g', style: TextStyle(color: Color(0xFF4285F4))),
                      TextSpan(text: 'l', style: TextStyle(color: Color(0xFF34A853))),
                      TextSpan(text: 'e', style: TextStyle(color: Color(0xFFEA4335))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  "S'inscrire avec Google",
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'ou avec email',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isPassword,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      onChanged: onChanged,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1),
        ),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final strength = _passwordStrength;
    return Row(
      children: [
        for (int i = 1; i <= 4; i++) ...[
          Expanded(
            child: Container(
              height: 4,
              decoration: BoxDecoration(
                color: i <= strength
                    ? _strengthColor
                    : Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (i < 4) const SizedBox(width: 4),
        ],
        const SizedBox(width: 12),
        Text(
          _strengthLabel,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _strengthColor,
          ),
        ),
      ],
    );
  }
}