import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
    // Note: Provider.of(context, listen: false) is the correct way to get the
    // AuthProvider here for the refreshListenable below.
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth, 
      
      routes: [
        GoRoute(path: '/splash', builder: (c, state) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (c, state) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (c, state) => LoginScreen()),
        GoRoute(path: '/register', builder: (c, state) => RegisterScreen()),
        GoRoute(
          path: '/home', 
          builder: (c, state) => const HomeScreen(), 
          routes: [
            GoRoute(path: 'explore', builder: (c, state) => const EventListScreen()),
            GoRoute(path: 'event/:id', builder: (c, state) {
              // FIX 2: Use state.pathParameters (New API) instead of state.params (Old API)
              final id = state.pathParameters['id']!;
              return EventDetailScreen(eventId: id);
            }),
            GoRoute(path: 'chat', builder: (c, state) => const ChatListScreen()),
            GoRoute(path: 'chat/:chatId', builder: (c, state) {
              // FIX 3: Use state.pathParameters (New API) instead of state.params (Old API)
              final chatId = state.pathParameters['chatId']!;
              return ChatRoomScreen(chatId: chatId);
            }),
            GoRoute(path: 'profile', builder: (c, state) => const ProfileScreen()),
          ],
        ),
      ],
      redirect: (context, state) {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = authProv.isLoggedIn;
        
        // FIX 4: Use state.matchedLocation (New API) instead of state.subloc (Old API)
        final goingTo = state.matchedLocation; 
        
        // Allowed non-authenticated routes
        final isAuthRoute = goingTo == '/login' || goingTo == '/register' || goingTo == '/onboarding' || goingTo == '/splash';

        if (goingTo == '/splash') return null; // Let the splash screen run

        if (!loggedIn) {
          // If not logged in, only allow auth routes, otherwise redirect to onboarding
          return isAuthRoute ? null : '/onboarding';
        }

        // If logged in, block access to auth routes, redirect to home
        if (isAuthRoute) return '/home';

        // Otherwise, allow navigation
        return null;
      },
    );
  }
}
