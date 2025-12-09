import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';
import 'config/firebase_options.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const EventraApp(),
    ),
  );
}
