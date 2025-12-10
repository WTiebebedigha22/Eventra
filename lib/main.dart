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

  final authProvider = AuthProvider();
  await authProvider.initialize();

  runApp(
    MultiProvider(
      providers: [
        // 3. Use .value constructor to provide the already-initialized instance
        ChangeNotifierProvider<AuthProvider>.value(
          value: authProvider,
        ),
      ],
      child: const EventraApp(),
    ),
  );
}