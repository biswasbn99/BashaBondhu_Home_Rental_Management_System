import 'package:bashabondhu_home_rental_management_system/app/bashabondhu_app.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS)) {
    FlutterError.onError = (errorDetails) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
      } else {
        FlutterError.presentError(errorDetails);
      }
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      if (kReleaseMode) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('⚠️ Caught Unhandled Error in Debug: $error');
      }
      return true;
    };
  } else {
    FlutterError.onError = FlutterError.presentError;
  }

  runApp(const BashabondhuApp());
}
