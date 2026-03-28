import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ── Utilisateur courant ───────────────────────────────────────────────────
  static User? get currentUser => _client.auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Session? get currentSession => _client.auth.currentSession;

  // ── Stream pour écouter les changements d'état ────────────────────────────
  static Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;

  // ── Inscription ───────────────────────────────────────────────────────────
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );
      if (res.user != null) return AuthResult.success();
      return AuthResult.error('Inscription échouée — vérifie ton email.');
    } on AuthException catch (e) {
      return AuthResult.error(_translateError(e.message));
    } catch (e) {
      return AuthResult.error('Erreur réseau. Vérifie ta connexion.');
    }
  }

  // ── Connexion ─────────────────────────────────────────────────────────────
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult.success();
    } on AuthException catch (e) {
      return AuthResult.error(_translateError(e.message));
    } catch (e) {
      return AuthResult.error('Erreur réseau. Vérifie ta connexion.');
    }
  }

  // ── Déconnexion ───────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  // ── Réinitialisation mot de passe ─────────────────────────────────────────
  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(email);
      return AuthResult.success(
        message: 'Email envoyé ! Vérifie ta boîte mail.',
      );
    } on AuthException catch (e) {
      return AuthResult.error(_translateError(e.message));
    } catch (e) {
      return AuthResult.error('Erreur réseau.');
    }
  }

  // ── Traduction des erreurs Supabase → français ────────────────────────────
  static String _translateError(String message) {
    final m = message.toLowerCase();
    if (m.contains('invalid login') || m.contains('invalid credentials')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (m.contains('email not confirmed')) {
      return 'Email non confirmé. Vérifie ta boîte mail.';
    }
    if (m.contains('user already registered')) {
      return 'Un compte existe déjà avec cet email.';
    }
    if (m.contains('password should be')) {
      return 'Le mot de passe doit contenir au moins 6 caractères.';
    }
    if (m.contains('rate limit')) {
      return 'Trop de tentatives. Réessaie dans quelques minutes.';
    }
    return message;
  }
}

// ── Résultat d'une opération auth ─────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? error;
  final String? message;

  const AuthResult._({required this.success, this.error, this.message});

  factory AuthResult.success({String? message}) =>
      AuthResult._(success: true, message: message);

  factory AuthResult.error(String error) =>
      AuthResult._(success: false, error: error);
}
