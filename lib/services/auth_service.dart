import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  static User? get currentUser => _auth.currentUser;
  static bool get isLoggedIn => currentUser != null;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static Future<AuthResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (fullName != null && fullName.isNotEmpty) {
        await cred.user?.updateDisplayName(fullName);
      }
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_translateError(e.code));
    } catch (_) {
      return AuthResult.error('Erreur réseau. Vérifie ta connexion.');
    }
  }

  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_translateError(e.code));
    } catch (_) {
      return AuthResult.error('Erreur réseau. Vérifie ta connexion.');
    }
  }

  static Future<AuthResult> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.error('Connexion Google annulée.');

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );
      await _auth.signInWithCredential(credential);
      return AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_translateError(e.code));
    } catch (_) {
      return AuthResult.error('Erreur lors de la connexion Google.');
    }
  }

  static Future<AuthResult> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: nonce,
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
      );

      await _auth.signInWithCredential(oauthCredential);
      return AuthResult.success();
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.error('Connexion Apple annulée.');
      }
      return AuthResult.error('Erreur Apple Sign-In.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_translateError(e.code));
    } catch (_) {
      return AuthResult.error('Erreur lors de la connexion Apple.');
    }
  }

  static String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  static String _sha256(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  static Future<AuthResult> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return AuthResult.success(message: 'Email envoyé ! Vérifie ta boîte mail.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_translateError(e.code));
    } catch (_) {
      return AuthResult.error('Erreur réseau.');
    }
  }

  static String _translateError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Email ou mot de passe incorrect.';
      case 'email-already-in-use':
        return 'Un compte existe déjà avec cet email.';
      case 'weak-password':
        return 'Le mot de passe doit contenir au moins 6 caractères.';
      case 'invalid-email':
        return 'Adresse email invalide.';
      case 'too-many-requests':
        return 'Trop de tentatives. Réessaie dans quelques minutes.';
      case 'network-request-failed':
        return 'Erreur réseau. Vérifie ta connexion.';
      default:
        return 'Erreur d\'authentification ($code).';
    }
  }
}

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
