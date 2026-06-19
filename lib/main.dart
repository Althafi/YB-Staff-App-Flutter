import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yb_staff_app/app.dart';
import 'package:yb_staff_app/core/services/fcm_service.dart';
import 'package:yb_staff_app/firebase_options.dart';

void main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FcmService.instance.setupBackgroundHandler();
  } catch (_) {
    // FCM features disabled — app still runs normally
  }

  await initializeDateFormatting('id_ID');

  runApp(
    const ProviderScope(
      child: App(),
    ),
  );
}
