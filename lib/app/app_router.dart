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
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return GoRouter(
      initialLocation: '/splash',
      refreshListenable: auth, 
      
      routes: [
        GoRoute(path: '/splash', builder: (c, state) => const SplashScreen()),
        GoRoute(path: '/onboarding', builder: (c, state) => const OnboardingScreen()),
        GoRoute(path: '/login', builder: (c, state) => const LoginScreen()),
        GoRoute(path: '/register', builder: (c, state) => const RegisterScreen()),
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
            GoRoute(path: 'profile', builder: (c, state) => const ProfileScreen()),
          ],
        ),
      ],
      redirect: (context, state) {
        final authProv = Provider.of<AuthProvider>(context, listen: false);
        final loggedIn = authProv.isLoggedIn;
        
        // 💡 ASSUMPTION: You must add this property to your AuthProvider
        final onboardingComplete = authProv.hasSeenOnboarding; 
        
        final goingTo = state.matchedLocation; 
        
        // Routes that should be accessible before or for authentication
        final isAuthOrOnboardingRoute = 
            goingTo == '/login' || 
            goingTo == '/register' || 
            goingTo == '/onboarding';

        // 1. Allow the splash screen to run first
        if (goingTo == '/splash') return null;

        // --- UNAUTHENTICATED FLOW ---
        if (!loggedIn) {
            // If the user is trying to go anywhere protected (not auth/onboarding)
            if (!isAuthOrOnboardingRoute) {
                // Check if onboarding is done. If not, go to onboarding. If yes, go to login.
                return onboardingComplete ? '/login' : '/onboarding'; 
            }
            // Otherwise (if they are on an auth/onboarding route), allow it.
            return null;
        }

        // --- AUTHENTICATED FLOW (The fix for the original issue) ---
        
        // 2. If logged in, block access to all auth/onboarding routes, redirect to home.
        if (isAuthOrOnboardingRoute) {
            // This prevents a user who just logged in and is navigating to '/home' 
            // from being redirected back to '/onboarding' or '/login'.
            return '/home'; 
        }

        // 3. Otherwise, allow navigation (logged in and going to a protected route)
        return null;
      },
    );
  }
}
