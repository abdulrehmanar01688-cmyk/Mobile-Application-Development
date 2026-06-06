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
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAEjSDmYkrwB8f-pK3DvlP0FFJaicP-ibk',
    appId: '1:236177362347:web:...',
    messagingSenderId: '236177362347',
    projectId: 'mysterybox-9de5c',
    authDomain: 'mysterybox-9de5c.firebaseapp.com',
    storageBucket: 'mysterybox-9de5c.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAEjSDmYkrwB8f-pK3DvlP0FFJaicP-ibk',
    appId: '1:236177362347:android:ce7272dad845452ebcd6ee',
    messagingSenderId: '236177362347',
    projectId: 'mysterybox-9de5c',
    storageBucket: 'mysterybox-9de5c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAEjSDmYkrwB8f-pK3DvlP0FFJaicP-ibk',
    appId: '1:236177362347:ios:...',
    messagingSenderId: '236177362347',
    projectId: 'mysterybox-9de5c',
    storageBucket: 'mysterybox-9de5c.firebasestorage.app',
    iosBundleId: 'com.example.mysterybox',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyAEjSDmYkrwB8f-pK3DvlP0FFJaicP-ibk',
    appId: '1:236177362347:ios:...',
    messagingSenderId: '236177362347',
    projectId: 'mysterybox-9de5c',
    storageBucket: 'mysterybox-9de5c.firebasestorage.app',
    iosBundleId: 'com.example.mysterybox',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAEjSDmYkrwB8f-pK3DvlP0FFJaicP-ibk',
    appId: '1:236177362347:web:...',
    messagingSenderId: '236177362347',
    projectId: 'mysterybox-9de5c',
    authDomain: 'mysterybox-9de5c.firebaseapp.com',
    storageBucket: 'mysterybox-9de5c.firebasestorage.app',
  );
}