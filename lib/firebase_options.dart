import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Options Firebase par plateforme.
/// Générées à partir des fichiers google-services.json (Android) et
/// GoogleService-Info.plist (iOS) du projet gen-lang-client-0845651189.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Web n\'est pas supporté — application mobile uniquement.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return ios;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAdMFoGS5wpuSwQv9vJ3148cV6zD6VpTxE',
    appId: '1:694709746993:android:77684bd4e6787dfc768410',
    messagingSenderId: '694709746993',
    projectId: 'gen-lang-client-0845651189',
    storageBucket: 'gen-lang-client-0845651189.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBgDIF0uyElGVlAxazcCjZxz0PbbLYqAtM',
    appId: '1:694709746993:ios:0b9d764809618e34768410',
    messagingSenderId: '694709746993',
    projectId: 'gen-lang-client-0845651189',
    storageBucket: 'gen-lang-client-0845651189.firebasestorage.app',
    iosClientId:
        '694709746993-8jcdtq1ud1gem5ihdiki58untcjf1e2a.apps.googleusercontent.com',
    iosBundleId: 'com.badaoui.cybrief',
  );
}
