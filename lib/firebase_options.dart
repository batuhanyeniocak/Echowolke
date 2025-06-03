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
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAGO2Rw4Wa_XWmB2nBPAgv1gYezrm5BWcA',
    appId: '1:252747795061:web:xxxxxxxxxxxxxxxxxxxxxx',
    messagingSenderId: '252747795061',
    projectId: 'echowolke',
    storageBucket: 'echowolke.appspot.com',
    authDomain: 'echowolke.firebaseapp.com',
    measurementId: 'G-XXXXXXX',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAGO2Rw4Wa_XWmB2nBPAgv1gYezrm5BWcA',
    appId: '1:252747795061:android:91f2da85e0fc01d334863c',
    messagingSenderId: '252747795061',
    projectId: 'echowolke',
    storageBucket: 'echowolke.appspot.com',
  );
}
