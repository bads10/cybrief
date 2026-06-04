import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_constants.dart';

class UserService {
  static const String _baseUrl = kApiBaseUrl;
  static const String _cachedUserKey = 'cached_user';

  // Sync user Firebase → backend après login
  static Future<Map<String, dynamic>?> syncUser({
    required String uid,
    required String email,
    String? displayName,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/users'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': uid, 'email': email, 'displayName': displayName}),
      );
      if (res.statusCode == 200 || res.statusCode == 201) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        await _cacheUser(user);
        return user;
      }
    } catch (_) {}
    return null;
  }

  // Récupérer le profil utilisateur
  static Future<Map<String, dynamic>?> getUser(String uid) async {
    try {
      final res = await http.get(Uri.parse('$_baseUrl/api/users/$uid'));
      if (res.statusCode == 200) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        await _cacheUser(user);
        return user;
      }
    } catch (_) {}
    return await getCachedUser();
  }

  // Mettre à jour les préférences
  static Future<bool> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      final res = await http.patch(
        Uri.parse('$_baseUrl/api/users/$uid'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );
      if (res.statusCode == 200) {
        final user = jsonDecode(res.body) as Map<String, dynamic>;
        await _cacheUser(user);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Supprimer le compte + données associées côté backend
  static Future<bool> deleteAccount(String uid) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/api/users/$uid'));
      if (res.statusCode == 200) {
        await clearCache();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Vérifier si l'user est premium
  static Future<bool> isPremium(String uid) async {
    final user = await getUser(uid);
    if (user == null) return false;
    final status = user['subscriptionStatus'] as String? ?? 'free';
    return status == 'premium' || status == 'trial';
  }

  // S'abonner à la newsletter
  static Future<bool> subscribeNewsletter(String uid, {String frequency = 'daily', String language = 'fr'}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/api/newsletter/subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': uid, 'frequency': frequency, 'language': language}),
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Se désabonner de la newsletter
  static Future<bool> unsubscribeNewsletter(String uid) async {
    try {
      final res = await http.delete(Uri.parse('$_baseUrl/api/newsletter/unsubscribe/$uid'));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  // Cache local
  static Future<void> _cacheUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cachedUserKey);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
  }
}
