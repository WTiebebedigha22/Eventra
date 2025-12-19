import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

// UI imports (Kept as provided)
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
  // FIX: Change 'late final' to a nullable private variable.
  GoRouter? _router;

  GoRouter router(AuthProvider auth) {
    // FIX: Use '??=' to only initialize the router if it hasn't been created yet.
    _router ??= GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isLoggedIn;
        final onboardingComplete = auth.hasSeenOnboarding;
        final location = state.matchedLocation;

        final isAuthRoute = location == '/login' ||
            location == '/register' ||
            location == '/forgot-password';

        final isOnboarding = location == '/onboarding';

        if (location == '/splash') return null;

        if (!loggedIn) {
          if (!onboardingComplete) return '/onboarding';
          if (!isAuthRoute) return '/login';
          return null;
        }

        if (loggedIn && (isAuthRoute || isOnboarding)) {
          return '/home/explore';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, _) => const RegisterScreen()),
        GoRoute(
          path: '/forgot-password',
          builder: (_, _) => const ForgotPasswordScreen(),
        ),

        /// MAIN TABS
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(navigationShell: navigationShell, child: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/explore',
                  builder: (_, _) => const EventListScreen(),
                  routes: [
                    GoRoute(
                      path: 'event/:id',
                      builder: (_, state) =>
                          EventDetailScreen(eventId: state.pathParameters['id']!),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/chat',
                  builder: (_, _) => const ChatListScreen(),
                  routes: [
                    GoRoute(
                      path: 'chat/:chatId',
                      builder: (_, state) =>
                          ChatRoomScreen(chatId: state.pathParameters['chatId']!),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/home/profile',
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

        /// CREATE POST
        GoRoute(
          path: '/create-post',
          builder: (_, _) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'tag-people',
              builder: (_, _) => const TagPeopleScreen(),
            ),
          ],
        ),

        /// SETTINGS
        GoRoute(
          path: '/settings',
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