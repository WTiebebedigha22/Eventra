import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// Your UI Imports
import '../providers/auth_provider.dart';
import '../ui/splash/splash_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/auth/forgot_password.dart';

import '../ui/home/home_screen.dart';
import '../ui/events/event_list_screen.dart';
import '../ui/events/event_detail_screen.dart';
import '../ui/chat/chat_list_screen.dart';
import '../ui/chat/chat_room_screen.dart';
import '../ui/profile/profile_screen.dart';
import '../ui/profile/edit_profile.dart';
import '../ui/profile/profile_settings.dart';
import '../ui/settings/activity.dart';
import '../ui/settings/help.dart';
import '../ui/settings/language.dart';
import '../ui/settings/notifications.dart';
import '../ui/settings/privacy.dart';
import '../ui/settings/security.dart';
import '../ui/settings/theme.dart';

// 💡 NEW IMPORTS for Post Creation and Tagging
import '../ui/post/create_post.dart'; 
import '../ui/post/tag_people.dart'; // ASSUME this file/widget exists

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

        // --- NEW: Forgot Password Route ---
        GoRoute(
          path: '/forgot-password',
          builder: (c, state) => const ForgotPasswordScreen(),
        ),

        // --- StatefulShellRoute for Main Tabs (Home Screen) ---
        StatefulShellRoute.indexedStack( 
          builder: (context, state, navigationShell) {
            return HomeScreen(
              navigationShell: navigationShell,
              child: navigationShell,
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/explore', 
                  builder: (c, state) => const EventListScreen(),
                  routes: [
                    GoRoute(
                      path: 'event/:id',
                      builder: (c, state) {
                        final id = state.pathParameters['id']!;
                        return EventDetailScreen(eventId: id);
                      }),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/chat', 
                  builder: (c, state) => const ChatListScreen(),
                  routes: [
                    GoRoute(
                      path: 'chat/:chatId',
                      builder: (c, state) {
                        final chatId = state.pathParameters['chatId']!;
                        return ChatRoomScreen(chatId: chatId);
                      }),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/profile',
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
          ],
        ),

        // --- CREATE POST ROUTE ---
        GoRoute(
          path: '/create-post',
          builder: (c, state) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'tag-people',
              builder: (c, state) => const TagPeopleScreen(),
            ),
          ],
        ),

        // --- SETTINGS ROUTES ---
        GoRoute(
          path: '/settings', 
          builder: (c, state) => const ProfileSettingsScreen(),
          routes: [
            GoRoute(path: 'security', builder: (c, state) => const SecurityScreen()),
            GoRoute(path: 'activity', builder: (c, state) => const ActivityScreen()),
            GoRoute(path: 'notifications', builder: (c, state) => const NotificationsScreen()),
            GoRoute(path: 'theme', builder: (c, state) => const ThemeScreen()),
            GoRoute(path: 'language', builder: (c, state) => const LanguageScreen()),
            GoRoute(path: 'help', builder: (c, state) => const HelpScreen()),
            GoRoute(path: 'privacy', builder: (c, state) => const PrivacyPolicyScreen()),
          ],
        ),
      ],
      
      // --- REDIRECT LOGIC ---
      redirect: (context, state) {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = authProv.isLoggedIn;
        final onboardingComplete = authProv.hasSeenOnboarding; 
        final goingTo = state.matchedLocation; 
        final isAuthOrOnboardingRoute = 
            goingTo == '/login' || goingTo == '/register' || goingTo == '/onboarding' || goingTo == '/forgot-password';

        if (goingTo == '/splash') return null;

        if (!loggedIn) {
            if (!isAuthOrOnboardingRoute) {
                return onboardingComplete ? '/login' : '/onboarding'; 
            }
            return null;
        }

        if (isAuthOrOnboardingRoute) {
            return '/home/explore'; 
        }

        return null;
      },
    );
  }
}
