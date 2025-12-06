// lib/app/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../features/onboarding/onboarding_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/signup_screen.dart';
import '../features/splash/splash_screen.dart';
import '../features/home/home_screen.dart';
import '../features/events/presentation/screens/event_list_screen.dart';
import '../features/events/presentation/screens/event_detail_screen.dart';
import '../features/chat/presentation/screens/chat_list_screen.dart';
import '../features/chat/presentation/screens/chat_room_screen.dart';
import '../features/profile/presentation/screens/profile_screen.dart';
import '../providers/auth_provider.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: GoRouterRefreshStream(auth.authStateChangesStream),
      debugLogDiagnostics: true,
      routes: [
        GoRoute(
          path: '/splash',
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/signup',
          name: 'signup',
          builder: (context, state) => const SignupScreen(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'explore',
              name: 'explore',
              builder: (context, state) => const EventListScreen(),
            ),
            GoRoute(
              path: 'vendor/:vendorId',
              name: 'vendor',
              builder: (context, state) {
                final id = state.params['vendorId']!;
                return EventDetailScreen(eventId: id);
              },
            ),
            GoRoute(
              path: 'chat',
              name: 'chat_list',
              builder: (context, state) => const ChatListScreen(),
            ),
            GoRoute(
              path: 'chat/:chatId',
              name: 'chat_room',
              builder: (context, state) {
                final chatId = state.params['chatId']!;
                return ChatRoomScreen(chatId: chatId);
              },
            ),
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
      redirect: (context, state) {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = authProv.isLoggedIn;
        final goingTo = state.subloc;

        // If still on splash, no redirect
        if (goingTo == '/splash') return null;

        // If not logged in, allow onboarding, login, signup; otherwise go to home
        if (!loggedIn) {
          if (goingTo == '/login' || goingTo == '/signup' || goingTo == '/onboarding') {
            return null;
          }
          return '/onboarding';
        }

        // If logged in and visiting onboarding/login/signup, send to home
        if (goingTo == '/onboarding' || goingTo == '/login' || goingTo == '/signup') {
          return '/home';
        }

        // No redirect
        return null;
      },
    );
  }
}
fl