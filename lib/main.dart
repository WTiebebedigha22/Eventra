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
import 'config/app_config.dart';        // ← NEW: moved OneSignal ID here
import 'config/firebase_options.dart';
import 'providers/auth_provider.dart';
import 'providers/post_provider.dart';
import 'providers/theme_provider.dart'; // ← NEW: moved ThemeProvider to its own file
import 'services/chat_service.dart';
import 'services/booking_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // FIX 1: Set language code to suppress X-Firebase-Locale null warning
    await FirebaseAuth.instance.setLanguageCode('en');

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
      appleProvider: AppleProvider.debug,     // Change to .deviceCheck for production
    );
  } catch (e) {
    // FIX 2: Show fallback UI if Firebase fails instead of crashing silently
    debugPrint("Firebase Initialization Error: $e");
    runApp(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    "Unable to connect",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Failed to initialize the app. Please check your connection and try again.\n\nDetails: $e",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return; // ← Stop execution so runApp below is never called
  }

  // 4. OneSignal Setup — must happen BEFORE any OneSignal.login() calls
  // FIX 3: App ID is now read from AppConfig (lib/config/app_config.dart)
  _initOneSignal();

  // 5. Auth & State initialization
  final authProvider = AuthProvider();
  await authProvider.initialize();

  // Sync user if already logged in
  // FIX 4: OneSignal is now guaranteed initialized before this call
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

        // FIX 5: ThemeProvider moved to lib/providers/theme_provider.dart
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(savedTheme),
        ),

        ChangeNotifierProvider<ChatProvider>(
          create: (_) => ChatProvider(ChatService()),
        ),

        ChangeNotifierProvider<PostProvider>(
          create: (_) => PostProvider(),
        ),

        // FIX 6: BookingService changed from ChangeNotifierProvider to Provider
        // because BookingService is a plain service class, not a ChangeNotifier.
        // If BookingService DOES extend ChangeNotifier, revert this to ChangeNotifierProvider.
        Provider<BookingService>(
          create: (_) => BookingService(),
        ),

        // TODO: Add a ChangeNotifierProvider here for a global unread
        // notification count if you plan to show a badge on the Activity tab.
      ],
      child: const EventraApp(),
    ),
  );
}

// ---------------------------------------------------------------------------
// OneSignal
// ---------------------------------------------------------------------------

/// Initializes OneSignal. Must be called before any OneSignal.login() call.
void _initOneSignal() {
  OneSignal.Debug.setLogLevel(OSLogLevel.none);

  // FIX 3: Read App ID from AppConfig instead of hardcoding it here.
  // See lib/config/app_config.dart
  OneSignal.initialize(AppConfig.oneSignalAppId);

  OneSignal.Notifications.requestPermission(true);

  // Handle notification tap while app is in foreground
  OneSignal.Notifications.addClickListener((event) {
    final data = event.notification.additionalData;
    debugPrint('Notification Clicked. Data: $data');
    // TODO: Use a global NavigatorKey to push to specific screens based on data.
  });
}

/// Links the signed-in Firebase user to OneSignal for targeted push notifications.
/// Call this after every successful sign-in, not just on app start.
void _syncUserWithOneSignal(User user) {
  OneSignal.login(user.uid);

  if (user.email != null) {
    OneSignal.User.addEmail(user.email!);
  }

  if (user.displayName != null) {
    OneSignal.User.addTags({"name": user.displayName!});
  }
}