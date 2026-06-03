import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordFocus = FocusNode();
  bool _loading       = false;
  bool _loadingGoogle = false;
  bool _loadingApple  = false;
  bool _showPassword  = false;
  String? _error;

  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Remplis tous les champs.');
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _error = 'Adresse e-mail invalide.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    final result = await AuthService.signIn(email: email, password: password);

    if (!mounted) return;
    setState(() => _loading = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/flux');
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _loginWithGoogle() async {
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

  Future<void> _loginWithApple() async {
    setState(() { _loadingApple = true; _error = null; });

    final result = await AuthService.signInWithApple();

    if (!mounted) return;
    setState(() => _loadingApple = false);

    if (result.success) {
      Navigator.pushReplacementNamed(context, '/flux');
    } else {
      setState(() => _error = result.error);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Entre ton email d\'abord.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final result = await AuthService.resetPassword(email);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.message ?? result.error ?? ''),
        backgroundColor: result.success
            ? const Color(0xFF22C55E)
            : const Color(0xFFEF4444),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A191E),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(40.0, 0, 40.0, 40.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.lock, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 32),
              Text(
                AppLocalizations.of(context)!.loginTitle,
                style: GoogleFonts.libreBaskerville(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Accédez à vos briefings de sécurité.',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 40),

              // ── Bouton Google ───────────────────────────────────────────
              _buildGoogleButton(),
              const SizedBox(height: 12),
              
              // ── Bouton Apple ────────────────────────────────────────────
              _buildAppleButton(),
              const SizedBox(height: 20),

              // ── Séparateur ──────────────────────────────────────────────
              _buildDivider(),
              const SizedBox(height: 20),

              // ── Champ email ────────────────────────────────────────────
              _buildFieldLabel('E-MAIL PROFESSIONNEL'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _emailCtrl,
                hint: 'nom@entreprise.com',
                isPassword: false,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                onSubmitted: () => _passwordFocus.requestFocus(),
              ),
              const SizedBox(height: 24),

              // ── Champ mot de passe ─────────────────────────────────────
              _buildFieldLabel('MOT DE PASSE'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _passwordCtrl,
                hint: '••••••••••••',
                isPassword: !_showPassword,
                focusNode: _passwordFocus,
                textInputAction: TextInputAction.done,
                onSubmitted: _login,
                suffixIcon: IconButton(
                  icon: Icon(
                    _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                    color: Colors.white.withValues(alpha: 0.3),
                    size: 20,
                  ),
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                ),
              ),
              const SizedBox(height: 8),

              // ── Mot de passe oublié ────────────────────────────────────
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading ? null : _forgotPassword,
                  child: Text(
                    AppLocalizations.of(context)!.forgotPassword,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.4),
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),

              // ── Message d'erreur ───────────────────────────────────────
              if (_error != null) ...[
                const SizedBox(height: 12),
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

              // ── Bouton connexion ───────────────────────────────────────
              ElevatedButton(
                onPressed: _loading ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0A191E),
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF0A191E),
                        ),
                      )
                    : Text(
                        AppLocalizations.of(context)!.signIn,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // ── Continuer sans compte ──────────────────────────────────
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/flux'),
                child: Text(
                  AppLocalizations.of(context)!.continueWithoutAccount,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // ── Lien inscription ───────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${AppLocalizations.of(context)!.noAccount} ',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/signup'),
                    child: Text(
                      AppLocalizations.of(context)!.signUp,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoogleButton() {
    return OutlinedButton(
      onPressed: (_loading || _loadingGoogle || _loadingApple) ? null : _loginWithGoogle,
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
                  AppLocalizations.of(context)!.continueWithGoogle,
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

  Widget _buildAppleButton() {
    return OutlinedButton(
      onPressed: (_loading || _loadingGoogle || _loadingApple) ? null : _loginWithApple,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(double.infinity, 56),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.white,
      ),
      child: _loadingApple
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.black,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.apple, color: Colors.black, size: 24),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.continueWithApple,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
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
            'ou',
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white.withValues(alpha: 0.6),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required bool isPassword,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    VoidCallback? onSubmitted,
    FocusNode? focusNode,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      focusNode: focusNode,
      textInputAction: textInputAction ?? TextInputAction.done,
      style: const TextStyle(color: Colors.white),
      onSubmitted: (_) => onSubmitted?.call(),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 1),
        ),
        suffixIcon: suffixIcon,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      ),
    );
  }
}