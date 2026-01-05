import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Provider Import
import '../providers/auth_provider.dart';

// UI Imports
import '../ui/splash/splash_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/auth/forgot_password.dart';
import '../ui/home/home_screen.dart';        
import '../ui/home/search_screen.dart';      
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
import '../ui/post/create_post.dart';
import '../ui/post/tag_people.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(debugLabel: 'homeFeed');
final _shellNavigatorChatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

class AppRouter {
  GoRouter? _router;

  GoRouter router(AuthProvider auth) {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: auth,

      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final onboardingComplete = auth.hasSeenOnboarding;
        final location = state.matchedLocation;

        // 1. Always allow Splash
        if (location == '/splash') return null;

        // 2. Identify Auth-Related pages
        final isAuthPage = location == '/login' || 
                           location == '/register' || 
                           location == '/forgot-password';

        // 3. Handle Unauthenticated Users
        if (!loggedIn) {
          // If they are trying to reach Register or Forgot Password, LET THEM PASS
          if (isAuthPage) return null;

          // If they haven't seen onboarding and aren't on an Auth page, send to onboarding
          if (!onboardingComplete && location != '/onboarding') {
            return '/onboarding';
          }
          
          // Otherwise, if they aren't logged in, they must be at /login
          return location == '/login' ? null : '/login';
        }

        // 4. Handle Authenticated Users
        if (loggedIn && (isAuthPage || location == '/' || location == '/splash')) {
          return '/home';
        }

        return null;
      },

      routes: [
        /// --- FULL SCREEN AUTH ---
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(path: '/forgot-password', builder: (_, _) => const ForgotPasswordScreen()),

        /// --- MAIN APP SHELL (Bottom Nav) ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(
              navigationShell: navigationShell,
              child: navigationShell, 
            );
          },
          branches: [
            /// BRANCH 0: HOME (LIVE POSTS)
            StatefulShellBranch(
              navigatorKey: _shellNavigatorHomeKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, _) => const EventListScreen(), // THIS IS YOUR FIRST PAGE
                  routes: [
                    GoRoute(
                      path: 'search', 
                      builder: (_, _) => const SearchScreen(),
                    ),
                    GoRoute(
                      path: 'event/:id',
                      builder: (_, state) => EventDetailScreen(
                        eventId: state.pathParameters['id']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// BRANCH 1: CHAT
            StatefulShellBranch(
              navigatorKey: _shellNavigatorChatKey,
              routes: [
                GoRoute(
                  path: '/chat',
                  builder: (_, _) => const ChatListScreen(),
                  routes: [
                    GoRoute(
                      path: 'room/:chatId',
                      builder: (_, state) => ChatRoomScreen(
                        chatId: state.pathParameters['chatId']!,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            /// BRANCH 2: PROFILE
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfileKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, _) => const EditProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        /// --- UTILITY (Pushed on top of Nav Bar) ---
        GoRoute(
          path: '/create-post',
          parentNavigatorKey: _rootNavigatorKey, 
          builder: (_, _) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'tag-people',
              builder: (_, _) => const TagPeopleScreen(),
            ),
          ],
        ),

        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const ProfileSettingsScreen(),
          routes: [
            GoRoute(path: 'security', builder: (_, _) => const SecurityScreen()),
            GoRoute(path: 'activity', builder: (_, _) => const ActivityScreen()),
            GoRoute(path: 'notifications', builder: (_, _) => const NotificationsScreen()),
            GoRoute(path: 'theme', builder: (_, _) => const ThemeScreen()),
            GoRoute(path: 'language', builder: (_, _) => const LanguageScreen()),
            GoRoute(path: 'help', builder: (_, _) => const HelpScreen()),
            GoRoute(path: 'privacy', builder: (_, _) => const PrivacyPolicyScreen()),
          ],
        ),
      ],
    );

    return _router!;
  }
}