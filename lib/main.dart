import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'config/firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // OneSignal Initialization
  final oneSignal = OneSignal.shared;
  await oneSignal.setAppId("729c13e9-37c8-4881-b376-2e8441e04a35");
  await oneSignal.promptUserForPushNotificationPermission();

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
      ],
      child: const EventraApp(),
    ),
  );
}
