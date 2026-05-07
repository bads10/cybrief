import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// Nom de l'application
  ///
  /// In fr, this message translates to:
  /// **'Cybrief'**
  String get appName;

  /// No description provided for @tagline.
  ///
  /// In fr, this message translates to:
  /// **'L\'essentiel de la menace en 2 minutes.'**
  String get tagline;

  /// No description provided for @dailyBriefTitle.
  ///
  /// In fr, this message translates to:
  /// **'Le Brief Cyber'**
  String get dailyBriefTitle;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @retry.
  ///
  /// In fr, this message translates to:
  /// **'Réessayer'**
  String get retry;

  /// No description provided for @noArticles.
  ///
  /// In fr, this message translates to:
  /// **'Aucun brief pour le moment.'**
  String get noArticles;

  /// No description provided for @connectionError.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de joindre le serveur. Vérifiez votre connexion.'**
  String get connectionError;

  /// No description provided for @quotaReachedTitle.
  ///
  /// In fr, this message translates to:
  /// **'Tu as lu tes 5 briefs du jour'**
  String get quotaReachedTitle;

  /// No description provided for @quotaReachedBody.
  ///
  /// In fr, this message translates to:
  /// **'Passe à Premium pour un accès illimité, les CVE complets et les alertes temps réel.'**
  String get quotaReachedBody;

  /// No description provided for @startFreeTrial.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'essai 7 jours gratuits'**
  String get startFreeTrial;

  /// No description provided for @premiumMonthlyPrice.
  ///
  /// In fr, this message translates to:
  /// **'9,99€/mois · 79,99€/an · Sans engagement'**
  String get premiumMonthlyPrice;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'PARAMÈTRES'**
  String get settings;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'COMPTE'**
  String get account;

  /// No description provided for @security.
  ///
  /// In fr, this message translates to:
  /// **'SÉCURITÉ'**
  String get security;

  /// No description provided for @notifications.
  ///
  /// In fr, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notifications;

  /// No description provided for @display.
  ///
  /// In fr, this message translates to:
  /// **'AFFICHAGE'**
  String get display;

  /// No description provided for @newsletter.
  ///
  /// In fr, this message translates to:
  /// **'NEWSLETTER'**
  String get newsletter;

  /// No description provided for @about.
  ///
  /// In fr, this message translates to:
  /// **'À PROPOS'**
  String get about;

  /// No description provided for @editProfile.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le profil'**
  String get editProfile;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get save;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'Se déconnecter'**
  String get logout;

  /// No description provided for @premiumBannerTitle.
  ///
  /// In fr, this message translates to:
  /// **'Passer à PREMIUM'**
  String get premiumBannerTitle;

  /// No description provided for @premiumBannerSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Accès illimité · Alertes temps réel · CVE exclusifs'**
  String get premiumBannerSubtitle;

  /// No description provided for @criticalAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes CRITIQUES'**
  String get criticalAlerts;

  /// No description provided for @highAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes ÉLEVÉES'**
  String get highAlerts;

  /// No description provided for @mediumAlerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes MOYENNES'**
  String get mediumAlerts;

  /// No description provided for @dailyDigest.
  ///
  /// In fr, this message translates to:
  /// **'Digest quotidien'**
  String get dailyDigest;

  /// No description provided for @darkMode.
  ///
  /// In fr, this message translates to:
  /// **'Mode sombre'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @english.
  ///
  /// In fr, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @newsletterFreqDaily.
  ///
  /// In fr, this message translates to:
  /// **'Quotidien'**
  String get newsletterFreqDaily;

  /// No description provided for @newsletterFreqWeekly.
  ///
  /// In fr, this message translates to:
  /// **'Hebdomadaire'**
  String get newsletterFreqWeekly;

  /// No description provided for @newsletterFreqOff.
  ///
  /// In fr, this message translates to:
  /// **'Désactivé'**
  String get newsletterFreqOff;

  /// No description provided for @paywallTitle.
  ///
  /// In fr, this message translates to:
  /// **'Intelligence cyber\nsans limites'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoins les professionnels de la sécurité\nqui ne manquent aucune menace.'**
  String get paywallSubtitle;

  /// No description provided for @paywallCta.
  ///
  /// In fr, this message translates to:
  /// **'Commencer l\'essai gratuit 7 jours'**
  String get paywallCta;

  /// No description provided for @restorePurchases.
  ///
  /// In fr, this message translates to:
  /// **'Restaurer mes achats'**
  String get restorePurchases;

  /// No description provided for @noCommitment.
  ///
  /// In fr, this message translates to:
  /// **'Sans engagement · Annulable à tout moment'**
  String get noCommitment;

  /// No description provided for @loginTitle.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get loginTitle;

  /// No description provided for @signupTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rejoindre Cybrief'**
  String get signupTitle;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'E-mail'**
  String get email;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @continueWithGoogle.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithApple.
  ///
  /// In fr, this message translates to:
  /// **'Continuer avec Apple'**
  String get continueWithApple;

  /// No description provided for @forgotPassword.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe oublié ?'**
  String get forgotPassword;

  /// No description provided for @noAccount.
  ///
  /// In fr, this message translates to:
  /// **'Pas encore de compte ?'**
  String get noAccount;

  /// No description provided for @alreadyAccount.
  ///
  /// In fr, this message translates to:
  /// **'Déjà un compte ?'**
  String get alreadyAccount;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In fr, this message translates to:
  /// **'S\'inscrire'**
  String get signUp;

  /// No description provided for @continueWithoutAccount.
  ///
  /// In fr, this message translates to:
  /// **'Continuer sans compte →'**
  String get continueWithoutAccount;

  /// No description provided for @termsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Conditions d\'utilisation'**
  String get termsTitle;

  /// No description provided for @privacyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Politique de confidentialité'**
  String get privacyTitle;

  /// No description provided for @termsIntro.
  ///
  /// In fr, this message translates to:
  /// **'En vous inscrivant, vous acceptez nos '**
  String get termsIntro;

  /// No description provided for @termsAnd.
  ///
  /// In fr, this message translates to:
  /// **' et notre '**
  String get termsAnd;

  /// No description provided for @loadingMore.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loadingMore;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
