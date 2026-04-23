import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ventra/providers/chat_provider.dart';
import 'app/app.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'services/chat_service.dart';
import 'services/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2. OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.none);
  OneSignal.initialize("729c13e9-37c8-4881-b376-2e8441e04a35");
  OneSignal.Notifications.requestPermission(true);

  // 3. Auth Provider
  final authProvider = AuthProvider();
  await authProvider.initialize();

  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    _syncUserWithOneSignal(firebaseUser);
  }

  // 4. Notification Click
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('Notification Data received: $data');
  });

  // 5. Load saved theme
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'System';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),

        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(ChatService()),
        ),

        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider(),
        ),

        ChangeNotifierProvider<BookingService>(
          create: (_) => BookingService(),
        ),

        // ✅ Theme Provider
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(savedTheme),
        ),
      ],
      child: const EventraApp(),
    ),
  );
}

/// Sync Firebase Identity with OneSignal
void _syncUserWithOneSignal(User user) {
  OneSignal.login(user.uid);

  if (user.email != null) {
    OneSignal.User.addEmail(user.email!);
  }

  if (user.displayName != null) {
    OneSignal.User.addTags({"name": user.displayName!});
  }
}

////////////////////////////////////////////////////////////
/// ✅ THEME PROVIDER (SAFE VERSION)
////////////////////////////////////////////////////////////

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentTheme = 'System';

  ThemeProvider(String savedTheme) {
    _applyTheme(savedTheme); // ✅ no async here
  }

  ThemeMode get themeMode => _themeMode;
  String get currentTheme => _currentTheme;

  Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme', theme);

    _applyTheme(theme);
    notifyListeners();
  }

  void _applyTheme(String theme) {
    _currentTheme = theme;

    switch (theme) {
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
  }
}