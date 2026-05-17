// أندرويد: متزامن مع android/app/google-services.json (مشروع dental-gate-notif).
// لإضافة iOS/Web شغّل: flutterfire configure

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
        return ios;
      case TargetPlatform.macOS:
        return ios;
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        return android;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions غير مهيأ لهذه المنصة.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_WEB_API_KEY',
    appId: '1:000000000000:web:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dental-gate-replace-me',
    authDomain: 'dental-gate-replace-me.firebaseapp.com',
    storageBucket: 'dental-gate-replace-me.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCH88lwviWjfL3hecFpeWzpiZR9AY-1y3g',
    appId: '1:867862771414:android:f457b71d9201948dacfb77',
    messagingSenderId: '867862771414',
    projectId: 'dental-gate-notif',
    storageBucket: 'dental-gate-notif.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_IOS_API_KEY',
    appId: '1:000000000000:ios:0000000000000000000000',
    messagingSenderId: '000000000000',
    projectId: 'dental-gate-replace-me',
    storageBucket: 'dental-gate-replace-me.appspot.com',
    iosBundleId: 'com.dentalgate.dentalGate',
  );
}
