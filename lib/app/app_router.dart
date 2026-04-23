import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Provider Import
import '../providers/auth_provider.dart' as custom;

// UI Imports
import '../ui/splash/splash_screen.dart';
import '../ui/onboarding/onboarding_screen.dart';
import '../ui/auth/login_screen.dart';
import '../ui/auth/register_screen.dart';
import '../ui/auth/forgot_password.dart';
import '../ui/bookings/ticket_purchase_screen.dart';
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
final _shellNavigatorHomeKey = GlobalKey<NavigatorState>(
  debugLabel: 'homeFeed',
);
final _shellNavigatorChatKey = GlobalKey<NavigatorState>(debugLabel: 'chat');
final _shellNavigatorProfileKey = GlobalKey<NavigatorState>(
  debugLabel: 'profile',
);
final _shellNavigatorSearchKey = GlobalKey<NavigatorState>(
  debugLabel: 'search',
);

class AppRouter {
  GoRouter? _router;

  GoRouter router(custom.AuthProvider auth) {
    _router ??= GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/splash',
      refreshListenable: auth,

      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final onboardingComplete = auth.hasSeenOnboarding;
        final location = state.matchedLocation;

        if (location == '/splash') return null;

        final isAuthPage =
            location == '/login' ||
            location == '/register' ||
            location == '/forgot-password';

        if (!loggedIn) {
          if (isAuthPage) return null;
          if (!onboardingComplete && location != '/onboarding') {
            return '/onboarding';
          }
          return '/login';
        }

        if (loggedIn &&
            (isAuthPage || location == '/' || location == '/splash')) {
          return '/home';
        }

        return null;
      },

      routes: [
        /// --- AUTH ROUTES ---
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(
          path: '/onboarding',
          builder: (_, _) => const OnboardingScreen(),
        ),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),

        /// --- MAIN APP SHELL ---
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(
              navigationShell: navigationShell,
              child: navigationShell,
            );
          },
          branches: [
            /// 🔹 HOME / EVENTS
            StatefulShellBranch(
              navigatorKey: _shellNavigatorHomeKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, _) => const EventListScreen(),
                  routes: [
                    // Event Details
                    GoRoute(
                      path: 'event/:id',
                      builder: (_, state) => EventDetailScreen(
                        eventId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          // The ':id' tells the router that this is a dynamic variable
                          path: 'purchase-tickets/:id',
                          name:
                              'purchaseTickets', // Adding a name makes navigation much easier
                          builder: (context, state) {
                            // Extract the ID from the path
                            final eventId = state.pathParameters['id']!;

                            return TicketPurchaseScreen(
                              eventId: eventId,
                              // We pass null for event because the screen fetches
                              // the data itself using the eventId via StreamBuilder
                              event: null,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            /// 🔹 CHAT
            StatefulShellBranch(
              navigatorKey: _shellNavigatorChatKey,
              routes: [
                GoRoute(
                  path: '/chat',
                  builder: (_, _) => const ChatListScreen(),
                ),
              ],
            ),

            /// 🔹 PROFILE
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfileKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) => ProfileScreen(
                    userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  ),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, _) => const EditProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),

            /// 🔹 SEARCH
            StatefulShellBranch(
              navigatorKey: _shellNavigatorSearchKey,
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (_, _) => const SearchScreen(),
                ),
              ],
            ),
          ],
        ),

        /// --- TOP-LEVEL ROUTES ---

        // Chat Room
        GoRoute(
          path: '/chat/room/:chatId/:otherUserId',
          parentNavigatorKey: _rootNavigatorKey,
          pageBuilder: (context, state) {
            final chatId = state.pathParameters['chatId']!;
            final otherUserId = state.pathParameters['otherUserId']!;
            final extra = state.extra as Map<String, dynamic>?;

            return MaterialPage(
              key: ValueKey('chat_room_$chatId'),
              child: ChatRoomScreen(
                chatId: chatId,
                otherUserId: otherUserId,
                otherUserName: extra?['peerName'] ?? 'User',
                otherUserProfilePic: extra?['peerAvatar'],
              ),
            );
          },
        ),

        // View Other User Profile
        GoRoute(
          path: '/user/:userId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) =>
              ProfileScreen(userId: state.pathParameters['userId']!),
        ),

        // Create Post
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

        // Settings
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, _) => const ProfileSettingsScreen(),
          routes: [
            GoRoute(
              path: 'security',
              builder: (_, _) => const SecurityScreen(),
            ),
            GoRoute(
              path: 'activity',
              builder: (_, _) => const ActivityScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (_, _) => const NotificationsScreen(),
            ),
            GoRoute(path: 'theme', builder: (_, _) => const ThemeScreen()),
            GoRoute(
              path: 'language',
              builder: (_, _) => const LanguageScreen(),
            ),
            GoRoute(path: 'help', builder: (_, _) => const HelpScreen()),
            GoRoute(
              path: 'privacy',
              builder: (_, _) => const PrivacyPolicyScreen(),
            ),
          ],
        ),
      ],
    );

    return _router!;
  }
}
