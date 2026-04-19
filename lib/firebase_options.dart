// PLACEHOLDER — Replace this file with the output of:
//   flutterfire configure
// after setting up your Firebase project at https://console.firebase.google.com

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
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️  REPLACE all placeholder values below with your real Firebase config.
  // Run: flutterfire configure
  // Docs: https://firebase.flutter.dev/docs/cli/

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBKRyMTGEGfLahYkVa1u-0y7ukHiDEl_Uk',
    appId: '1:1004880675178:android:6cdaf56da0e4a98fe86513',
    messagingSenderId: '1004880675178',
    projectId: 'flipnotes-8758c',
    storageBucket: 'flipnotes-8758c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBKRyMTGEGfLahYkVa1u-0y7ukHiDEl_Uk',
    appId: '1:1004880675178:ios:6cdaf56da0e4a98fe86513',
    messagingSenderId: '1004880675178',
    projectId: 'flipnotes-8758c',
    storageBucket: 'flipnotes-8758c.firebasestorage.app',
    iosBundleId: 'com.flipnotes.flipnotes',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBKRyMTGEGfLahYkVa1u-0y7ukHiDEl_Uk',
    appId: '1:1004880675178:web:6cdaf56da0e4a98fe86513',
    messagingSenderId: '1004880675178',
    projectId: 'flipnotes-8758c',
    authDomain: 'flipnotes-8758c.firebaseapp.com',
    storageBucket: 'flipnotes-8758c.firebasestorage.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBKRyMTGEGfLahYkVa1u-0y7ukHiDEl_Uk',
    appId: '1:1004880675178:ios:6cdaf56da0e4a98fe86513',
    messagingSenderId: '1004880675178',
    projectId: 'flipnotes-8758c',
    storageBucket: 'flipnotes-8758c.firebasestorage.app',
    iosBundleId: 'com.flipnotes.flipnotes',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBKRyMTGEGfLahYkVa1u-0y7ukHiDEl_Uk',
    appId: '1:1004880675178:web:6cdaf56da0e4a98fe86513',
    messagingSenderId: '1004880675178',
    projectId: 'flipnotes-8758c',
    authDomain: 'flipnotes-8758c.firebaseapp.com',
    storageBucket: 'flipnotes-8758c.firebasestorage.app',
  );
}
