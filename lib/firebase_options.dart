import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError('iOS platformu henüz yapılandırılmamış.');
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions ${defaultTargetPlatform.name} platformu için desteklenmiyor.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey:
        'AIzaSyALs3IlDu6CMIEm-nWAjecdH9H9tmGmxNU', // Kopyaladığınızı yapıştırın
    appId:
        '1:252747795061:web:d3be1063964bf74134863c', // Kopyaladığınızı yapıştırın
    messagingSenderId: '252747795061', // Kopyaladığınızı yapıştırın
    projectId: 'echowolke', // Kontrol edin, genelde aynı kalır
    storageBucket:
        'echowolke.firebasestorage.app', // Kontrol edin, genelde aynı kalır
    authDomain: 'echowolke.firebaseapp.com', // Kopyaladığınızı yapıştırın
    measurementId: 'G-50H18X7SK8', // Kopyaladığınızı yapıştırın
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY',
        defaultValue: 'AIzaSyAGO2Rw4Wa_XWmB2nBPAgv1gYezrm5BWcA'),
    appId: String.fromEnvironment('FIREBASE_APP_ID_ANDROID',
        defaultValue: '1:252747795061:android:91f2da85e0fc01d334863c'),
    messagingSenderId: '252747795061',
    projectId: 'echowolke',
    storageBucket: 'echowolke.appspot.com',
  );
}
