// Сгенерировано вручную по данным из Firebase Console (аналог того, что
// создаёт `flutterfire configure`) — на этой машине нет доступа к
// FlutterFire CLI. Значения не секретны: это публичные идентификаторы
// клиента, которые и так попадают в собранное приложение.
//
// ignore_for_file: type=lint

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Настройки Firebase по платформе — используется как
/// `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions не настроены для платформы '
          '${defaultTargetPlatform.name} — push-уведомления работают '
          'только на Android, iOS и Web.',
        );
    }
  }

  static const web = FirebaseOptions(
    apiKey: 'AIzaSyCwKWHefRY_95kmxFMAfAh2_inXtslOyBA',
    appId: '1:400066393277:web:f7f79a4fb42ef1d3f9b3d4',
    messagingSenderId: '400066393277',
    projectId: 'fixmygastro',
    authDomain: 'fixmygastro.firebaseapp.com',
    storageBucket: 'fixmygastro.firebasestorage.app',
    measurementId: 'G-LF5YMKKE58',
  );

  static const android = FirebaseOptions(
    apiKey: 'AIzaSyANeDvJuwmaaesumDqWzCdYb7qi2BtSGdo',
    appId: '1:400066393277:android:36499409260b045ef9b3d4',
    messagingSenderId: '400066393277',
    projectId: 'fixmygastro',
    storageBucket: 'fixmygastro.firebasestorage.app',
  );

  static const ios = FirebaseOptions(
    apiKey: 'AIzaSyDHL7lU8RrqZP00XWNUKc4RT_bE7M3l5_U',
    appId: '1:400066393277:ios:6fd6dc443b742e73f9b3d4',
    messagingSenderId: '400066393277',
    projectId: 'fixmygastro',
    storageBucket: 'fixmygastro.firebasestorage.app',
    iosBundleId: 'com.projectservice.projectService',
  );
}
