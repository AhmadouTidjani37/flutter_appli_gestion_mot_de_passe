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
    apiKey: 'AIzaSyCLe4vhePWkVxG4xlK7h1T0oKDsngkOFDk',
    appId: '1:161148335996:web:5de9cd7a7a2a8b5541d6f9',
    messagingSenderId: '161148335996',
    projectId: 'metoo-io-24e28',
    authDomain: 'metoo-io-24e28.firebaseapp.com',
    databaseURL: 'https://metoo-io-24e28-default-rtdb.firebaseio.com',
    storageBucket: 'metoo-io-24e28.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDmFjsH1ATTil0htnC_kZ9BaA0qXZmvFdo',
    appId: '1:161148335996:android:0389c7f5ed78736b41d6f9',
    messagingSenderId: '161148335996',
    projectId: 'metoo-io-24e28',
    databaseURL: 'https://metoo-io-24e28-default-rtdb.firebaseio.com',
    storageBucket: 'metoo-io-24e28.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDaWOuV7G4uqiZhaT5UAIzwj3rYj7ED89A',
    appId: '1:161148335996:ios:94df2b7387d057f941d6f9',
    messagingSenderId: '161148335996',
    projectId: 'metoo-io-24e28',
    databaseURL: 'https://metoo-io-24e28-default-rtdb.firebaseio.com',
    storageBucket: 'metoo-io-24e28.appspot.com',
    iosBundleId: 'com.example.gestMdp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDaWOuV7G4uqiZhaT5UAIzwj3rYj7ED89A',
    appId: '1:161148335996:ios:94df2b7387d057f941d6f9',
    messagingSenderId: '161148335996',
    projectId: 'metoo-io-24e28',
    databaseURL: 'https://metoo-io-24e28-default-rtdb.firebaseio.com',
    storageBucket: 'metoo-io-24e28.appspot.com',
    iosBundleId: 'com.example.gestMdp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA4d7H8k0JMHYXGPiBVoSZVA5tIhI-tE4M',
    appId: '1:161148335996:web:967c343a69ac97b741d6f9',
    messagingSenderId: '161148335996',
    projectId: 'metoo-io-24e28',
    authDomain: 'metoo-io-24e28.firebaseapp.com',
    databaseURL: 'https://metoo-io-24e28-default-rtdb.firebaseio.com',
    storageBucket: 'metoo-io-24e28.appspot.com',
  );
}
