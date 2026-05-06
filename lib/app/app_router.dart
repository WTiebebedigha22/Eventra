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
import '../ui/bookings/payment_screen.dart';
import '../ui/bookings/qr_ticket_screen.dart';
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
import '../ui/post/post_detail.dart';
import '../ui/post/tag_people.dart';
import '../ui/home/explore_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final _shellNavigatorHomeKey =
    GlobalKey<NavigatorState>(debugLabel: 'homeFeed');
final _shellNavigatorChatKey =
    GlobalKey<NavigatorState>(debugLabel: 'chat');
final _shellNavigatorExploreKey =
    GlobalKey<NavigatorState>(debugLabel: 'explore');
final _shellNavigatorSearchKey =
    GlobalKey<NavigatorState>(debugLabel: 'search');
final _shellNavigatorProfileKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

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

        final isAuthPage = location == '/login' ||
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
        // ───────────────── AUTH ─────────────────
        GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
        GoRoute(
            path: '/onboarding',
            builder: (_, __) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
        GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
        GoRoute(
            path: '/forgot-password',
            builder: (_, __) => const ForgotPasswordScreen()),

        // ───────────────── MAIN APP ─────────────────
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return HomeScreen(
              navigationShell: navigationShell,
              child: navigationShell,
            );
          },
          branches: [

            // ── HOME / EVENTS ──
            // Branch index: 0  →  nav index 0
            StatefulShellBranch(
              navigatorKey: _shellNavigatorHomeKey,
              routes: [
                GoRoute(
                  path: '/home',
                  builder: (_, __) => const EventListScreen(),
                  routes: [
                    GoRoute(
                      path: 'event/:id',
                      builder: (_, state) => EventDetailScreen(
                        eventId: state.pathParameters['id']!,
                      ),
                      routes: [
                        GoRoute(
                          path: 'purchase-tickets',
                          name: 'purchaseTickets',
                          builder: (context, state) {
                            final eventId = state.pathParameters['id'];

                            if (eventId == null || eventId.isEmpty) {
                              return const Scaffold(
                                body: Center(
                                  child: Text("Invalid Event ID"),
                                ),
                              );
                            }

                            return TicketPurchaseScreen(
                              eventId: eventId,
                              event: state.extra as Map<String, dynamic>?,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // ── CHAT / MESSAGES ──
            // Branch index: 1  →  nav index 1
            StatefulShellBranch(
              navigatorKey: _shellNavigatorChatKey,
              routes: [
                GoRoute(
                  path: '/chat',
                  builder: (_, __) => const ChatListScreen(),
                ),
              ],
            ),

            // ── EXPLORE  (FAB: create post sits above this tab in HomeScreen) ──
            // Branch index: 2  →  nav index 2  (centre tab)
            StatefulShellBranch(
              navigatorKey: _shellNavigatorExploreKey,
              routes: [
                GoRoute(
                  path: '/explore',
                  builder: (_, __) => const MasonryExploreScreen(),
                ),
              ],
            ),

            // ── SEARCH ──
            // Branch index: 3  →  nav index 3
            StatefulShellBranch(
              navigatorKey: _shellNavigatorSearchKey,
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (_, __) => const SearchScreen(),
                ),
              ],
            ),

            // ── PROFILE ──
            // Branch index: 4  →  nav index 4
            StatefulShellBranch(
              navigatorKey: _shellNavigatorProfileKey,
              routes: [
                GoRoute(
                  path: '/profile',
                  builder: (_, _) {
                    final uid = FirebaseAuth.instance.currentUser?.uid;

                    if (uid == null) {
                      return const Scaffold(
                        body: Center(child: Text("User not logged in")),
                      );
                    }

                    return ProfileScreen(userId: uid);
                  },
                  routes: [
                    GoRoute(
                      path: 'edit',
                      builder: (_, _) {
                        final uid = FirebaseAuth.instance.currentUser?.uid;

                        if (uid == null) {
                          return const Scaffold(
                            body: Center(child: Text("User not logged in")),
                          );
                        }
                        return EditProfileScreen(userId: uid);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        // ───────────────── PAYMENT ─────────────────
        GoRoute(
          path: '/payment',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;

            if (extra == null) {
              return const Scaffold(
                body: Center(child: Text("Missing payment details")),
              );
            }

            return PaymentScreen(
              eventId: extra['eventId'] as String,
              ticketId: extra['ticketId'] as String,
              totalAmount: (extra['totalAmount'] as num).toDouble(),
              quantity: extra['quantity'] as int,
            );
          },
        ),

        // ───────────────── TICKET QR ─────────────────
        GoRoute(
          path: '/ticket/:ticketId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final ticketId = state.pathParameters['ticketId'];

            if (ticketId == null || ticketId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Invalid Ticket ID")),
              );
            }

            return TicketScreen(ticketId: ticketId);
          },
        ),

        // ───────────────── CHAT ROOM ─────────────────
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

        // ───────────────── OTHER USER PROFILE ─────────────────
        GoRoute(
          path: '/user/:userId',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final userId = state.pathParameters['userId'];

            if (userId == null || userId.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Invalid User ID")),
              );
            }

            return ProfileScreen(userId: userId);
          },
        ),

        // ───────────────── POST DETAIL ─────────────────
        GoRoute(
          path: '/post/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final id = state.pathParameters['id'];

            if (id == null || id.isEmpty) {
              return const Scaffold(
                body: Center(child: Text("Invalid Post ID")),
              );
            }

            return PostDetailScreen(postId: id);
          },
        ),

        // ───────────────── CREATE POST ─────────────────
        GoRoute(
          path: '/create-post',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const CreatePostScreen(),
          routes: [
            GoRoute(
              path: 'tag-people',
              builder: (_, __) => const TagPeopleScreen(),
            ),
          ],
        ),

        // ───────────────── SETTINGS ─────────────────
        GoRoute(
          path: '/settings',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => const ProfileSettingsScreen(),
          routes: [
            GoRoute(
              path: 'security',
              builder: (_, __) => const SecurityScreen(),
            ),
            GoRoute(
              path: 'activity',
              builder: (_, __) => const ActivityScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (_, __) => const NotificationsScreen(),
            ),
            GoRoute(
              path: 'theme',
              builder: (_, __) => const ThemeScreen(),
            ),
            GoRoute(
              path: 'language',
              builder: (_, __) => const LanguageScreen(),
            ),
            GoRoute(
              path: 'help',
              builder: (_, __) => const HelpScreen(),
            ),
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