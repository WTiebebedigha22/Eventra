import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// UI imports
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
import '../ui/post/create_post.dart';
import '../ui/post/tag_people.dart';

class AppRouter {
  GoRouter? _router;

  GoRouter router(AuthProvider auth) {
    _router ??= GoRouter(
      initialLocation: '/',

      refreshListenable: auth,

      /// 🔐 AUTH & STARTUP REDIRECTS
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final onboardingComplete = auth.hasSeenOnboarding;
        final location = state.matchedLocation;

        // Root always goes to splash
        if (location == '/') return '/splash';

        if (location == '/splash') return null;

        if (!loggedIn) {
          if (!onboardingComplete) return '/onboarding';

          if (location != '/login' &&
              location != '/register' &&
              location != '/forgot-password') {
            return '/login';
          }
          return null;
        }

        if (loggedIn && location == '/login') {
          return '/home/explore';
        }

        return null;
      },

      routes: [
        /// ROOT
        GoRoute(
          path: '/',
          redirect: (_, __) => '/splash',
        ),

        /// AUTH FLOW
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen(),
        ),

        /// SHELL ENTRY
        GoRoute(
          path: '/home',
          redirect: (_, __) => '/home/explore',
        ),

        /// MAIN APP SHELL
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(
              navigationShell: navigationShell,
              child: navigationShell,
            );
          },
          branches: [
            /// EXPLORE TAB
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/explore',
                  builder: (_, __) => const EventListScreen(),
                  routes: [
                    GoRoute(
                      path: 'event/:id',
                      builder: (_, state) =>
                          EventDetailScreen(
                            eventId: state.pathParameters['id']!,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            /// CHAT TAB
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/chat',
                  builder: (_, __) => const ChatListScreen(),
                  routes: [
                    GoRoute(
                      path: 'chat/:chatId',
                      builder: (_, state) =>
                          ChatRoomScreen(
                            chatId: state.pathParameters['chatId']!,
                          ),
                    ),
                  ],
                ),
              ],
            ),

            /// PROFILE TAB
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/profile',
                  builder: (_, __) => const ProfileScreen(),
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, __) => const EditProfileScreen(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        /// CREATE POST
        GoRoute(
          path: '/create-post',
          builder: (_, __) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'tag-people',
              builder: (_, __) => const TagPeopleScreen(),
            ),
          ],
        ),

        /// SETTINGS
        GoRoute(
          path: '/settings',
          builder: (_, __) => const ProfileSettingsScreen(),
          routes: [
            GoRoute(path: 'security', builder: (_, __) => const SecurityScreen()),
            GoRoute(path: 'activity', builder: (_, __) => const ActivityScreen()),
            GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(path: 'theme', builder: (_, __) => const ThemeScreen()),
            GoRoute(path: 'language', builder: (_, __) => const LanguageScreen()),
            GoRoute(path: 'help', builder: (_, __) => const HelpScreen()),
            GoRoute(
              path: 'privacy',
              builder: (_, __) => const PrivacyPolicyScreen(),
            ),
          ],
        ),
      ],
    );

    return _router!;
  }
}
