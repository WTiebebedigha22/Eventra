import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ventra/ui/profile/edit_profile.dart';
import 'package:ventra/ui/profile/profile_settings.dart';
import 'package:ventra/ui/settings/activity.dart';
import 'package:ventra/ui/settings/help.dart';
import 'package:ventra/ui/settings/language.dart';
import 'package:ventra/ui/settings/notifications.dart';
import 'package:ventra/ui/settings/privacy.dart';
import 'package:ventra/ui/settings/security.dart';
import 'package:ventra/ui/settings/theme.dart';
import '../providers/auth_provider.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/splash/splash_screen.dart';
import '../ui/home/home_screen.dart';
import '../ui/events/event_list_screen.dart';
import '../ui/events/event_detail_screen.dart';
import '../ui/chat/chat_list_screen.dart';
import '../ui/chat/chat_room_screen.dart';
import '../ui/profile/profile_screen.dart';


class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth, 
      
      routes: [
        GoRoute(path: '/splash', builder: (c, state) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (c, state) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (c, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, state) => const RegisterScreen()),

        // --- HOME (SHELL) AND NESTED ROUTES ---
        GoRoute(
          path: '/home', 
          builder: (c, state) => const HomeScreen(), 
          routes: [
            GoRoute(path: 'explore', builder: (c, state) => const EventListScreen()),
            GoRoute(path: 'event/:id', builder: (c, state) {
              final id = state.pathParameters['id']!;
              return EventDetailScreen(eventId: id);
            }),
            GoRoute(path: 'chat', builder: (c, state) => const ChatListScreen()),
            GoRoute(path: 'chat/:chatId', builder: (c, state) {
              final chatId = state.pathParameters['chatId']!;
              return ChatRoomScreen(chatId: chatId);
            }),
            GoRoute(
              path: 'profile', // Matches /home/profile
              builder: (c, state) => const ProfileScreen(), 
              routes: [
                GoRoute(
                  path: 'edit', 
                  builder: (c, state) => const EditProfileScreen(),
                ),
              ],
            ),
          ],
        ),

        GoRoute(
          path: '/settings', 
          builder: (c, state) => const ProfileSettingsScreen(),
          routes: [
            // Account Group
            GoRoute(path: 'security', builder: (c, state) => const SecurityScreen()),
            GoRoute(path: 'activity', builder: (c, state) => const ActivityScreen()),

            // Content & Display Group
            GoRoute(path: 'notifications', builder: (c, state) => const NotificationsScreen()),
            GoRoute(path: 'theme', builder: (c, state) => const ThemeScreen()),
            GoRoute(path: 'language', builder: (c, state) => const LanguageScreen()),

            // Support & About Group
            GoRoute(path: 'help', builder: (c, state) => const HelpScreen()),
            GoRoute(path: 'privacy', builder: (c, state) => const PrivacyPolicyScreen()),
          ],
        ),
      ],
      
      // --- REDIRECT LOGIC (UNCHANGED) ---
      redirect: (context, state) {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = authProv.isLoggedIn;
        final onboardingComplete = authProv.hasSeenOnboarding; 
        
        final goingTo = state.matchedLocation; 
        
        final isAuthOrOnboardingRoute = 
            goingTo == '/login' || 
            goingTo == '/register' || 
            goingTo == '/onboarding';

        if (goingTo == '/splash') return null;

        if (!loggedIn) {
            if (!isAuthOrOnboardingRoute) {
                return onboardingComplete ? '/login' : '/onboarding'; 
            }
            return null;
        }

        if (isAuthOrOnboardingRoute) {
            return '/home'; 
        }

        return null;
      },
    );
  }
}