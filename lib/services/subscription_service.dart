import 'dart:io';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionService {
  // IDs produits App Store / Play Store
  static const String _monthlyId  = 'cybrief_monthly';
  static const String _yearlyId   = 'cybrief_annuel';

  // Entitlements RevenueCat
  static const String _premiumEntitlement = 'premium';

  // API Keys RevenueCat
  static const String _appleApiKey  = 'appl_owCkvISMMaJfIPhBtXPUasGIVWB';
  static const String _googleApiKey = 'goog_FdEnmWrkQPBZpJOswgfSSNERcSh';

  static bool _initialized = false;

  // Initialiser RevenueCat au démarrage de l'app
  static Future<void> initialize(String? userId) async {
    if (_initialized) return;
    await Purchases.setLogLevel(LogLevel.debug);

    final apiKey = Platform.isIOS ? _appleApiKey : _googleApiKey;
    final config = PurchasesConfiguration(apiKey);

    if (userId != null) {
      config.appUserID = userId;
    }

    await Purchases.configure(config);
    _initialized = true;
  }

  // Identifier l'user dans RevenueCat après login
  static Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (_) {}
  }

  // Déconnecter l'user de RevenueCat
  static Future<void> logOut() async {
    try {
      await Purchases.logOut();
    } catch (_) {}
  }

  // Vérifier si l'user est premium
  static Future<bool> isPremium() async {
    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(_premiumEntitlement);
    } catch (_) {
      return false;
    }
  }

  // Récupérer les offres disponibles
  static String? lastOfferingsError;
  static Future<Offerings?> getOfferings() async {
    try {
      lastOfferingsError = null;
      return await Purchases.getOfferings();
    } catch (e) {
      lastOfferingsError = e.toString();
      return null;
    }
  }

  // Acheter un package
  static Future<({bool success, String? error})> purchasePackage(Package package) async {
    try {
      final info = await Purchases.purchasePackage(package);
      final active = info.entitlements.active.containsKey(_premiumEntitlement);
      return (success: active, error: null);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return (success: false, error: null);
      }
      return (success: false, error: _translateError(e));
    } catch (e) {
      return (success: false, error: e.toString());
    }
  }

  // Restaurer les achats
  static Future<({bool success, String? error})> restorePurchases() async {
    try {
      final info = await Purchases.restorePurchases();
      final active = info.entitlements.active.containsKey(_premiumEntitlement);
      return (success: active, error: active ? null : 'Aucun abonnement actif trouvé.');
    } catch (e) {
      return (success: false, error: 'Erreur lors de la restauration.');
    }
  }

  static String _translateError(PurchasesErrorCode code) {
    switch (code) {
      case PurchasesErrorCode.networkError:
        return 'Erreur réseau. Vérifie ta connexion.';
      case PurchasesErrorCode.storeProblemError:
        return 'Problème avec l\'App Store. Réessaie.';
      case PurchasesErrorCode.receiptAlreadyInUseError:
        return 'Cet achat est déjà associé à un autre compte.';
      default:
        return 'Erreur lors de l\'achat. Réessaie.';
    }
  }
}
