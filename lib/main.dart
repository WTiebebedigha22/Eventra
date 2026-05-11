import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Your Imports
import 'package:ventra/providers/chat_provider.dart';
import 'app/app.dart';
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'services/chat_service.dart';
import 'services/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Firestore Stability Configuration
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // 3. App Check Configuration 
    // WARNING: If you get "Unauthorized" errors, comment this block out 
    // until you've added your SHA-256 and Debug tokens to Firebase Console.
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug, // Change to .playIntegrity for production
      appleProvider: AppleProvider.debug,    // Change to .deviceCheck for production
    );

  } catch (e) {
    debugPrint("Firebase Initialization Error: $e");
  }

  // 4. OneSignal Setup
  _initOneSignal();

  // 5. Auth & State initialization
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Sync user if already logged in
  final User? firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser != null) {
    _syncUserWithOneSignal(firebaseUser);
  }

  // 6. Theme Initialization
  final prefs = await SharedPreferences.getInstance();
  final savedTheme = prefs.getString('theme') ?? 'System';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(savedTheme),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(ChatService()),
        ),
        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider(),
        ),
        ChangeNotifierProvider<BookingService>(
          create: (_) => BookingService(),
        ),
        // Add a provider here if you plan to track unread notification counts globally
      ],
      child: const EventraApp(),
    ),
  );
}

/// OneSignal Initialization Logic
void _initOneSignal() {
  OneSignal.Debug.setLogLevel(OSLogLevel.none);
  OneSignal.initialize("729c13e9-37c8-4881-b376-2e8441e04a35");
  OneSignal.Notifications.requestPermission(true);

  // Handle what happens when a user clicks a notification while app is open
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('Notification Clicked. Data: $data');
    // You can use a global navigator key here to push to specific screens
  });
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
/// THEME PROVIDER
////////////////////////////////////////////////////////////

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String _currentTheme = 'System';

  ThemeProvider(String savedTheme) {
    _applyTheme(savedTheme);
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