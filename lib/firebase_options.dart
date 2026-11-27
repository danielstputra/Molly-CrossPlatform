import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for Molly AI Studio CrossPlatform.
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
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for windows');
      case TargetPlatform.linux:
        throw UnsupportedError('DefaultFirebaseOptions have not been configured for linux');
      default:
        throw UnsupportedError('DefaultFirebaseOptions are not supported for this platform.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForCrashlyticsTelemetry01',
    appId: '1:1071006060591:android:7d8a9b0c1e2f3a4b',
    messagingSenderId: '1071006060591',
    projectId: 'molly-ai-crossplatform',
    storageBucket: 'molly-ai-crossplatform.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummyKeyForCrashlyticsTelemetry01',
    appId: '1:1071006060591:ios:7d8a9b0c1e2f3a4b',
    messagingSenderId: '1071006060591',
    projectId: 'molly-ai-crossplatform',
    storageBucket: 'molly-ai-crossplatform.appspot.com',
    iosBundleId: 'com.molly.crossplatform',
  );

  static const FirebaseOptions macos = ios;
  static const FirebaseOptions web = android;
}
