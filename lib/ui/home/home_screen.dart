import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Define your color scheme (consistent)
  static const Color primaryPink = Color(0xFFE91E63); 
  static const Color backgroundColor = Colors.black;
  static const Color navBarColor = Color(0xFF181818); 
  static const Color textColor = Colors.white;

  // The tabs map to the full paths defined in your AppRouter
  final List<String> tabs = const ['/home/explore', '/home/chat', '/home/profile'];

  // Dynamic Index Finder (to sync the bottom bar with the current URL)
  int _getCurrentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    
    if (location.startsWith('/home/explore')) return 0;
    if (location.startsWith('/home/chat')) return 1;
    if (location.startsWith('/home/profile')) return 2;
    
    return 0;
  }

  void _onTap(int i) {
    // Navigate to the full path of the selected tab
    context.go(tabs[i]);
  }

  @override
  Widget build(BuildContext context) {
    final int currentIndex = _getCurrentIndex(context);
    
    return Scaffold(
      backgroundColor: backgroundColor,
      
      // --- FIXED BODY ---
      // The body must be a placeholder that GoRouter's underlying Navigator 
      // uses to draw the child screen (EventListScreen, etc.).
      // By using a Builder and the correct Key, the child navigator's content 
      // can be rendered here.
      body: SafeArea(
        // The KeyedSubtree widget is used to tell GoRouter where to draw the 
        // content of the current nested route.
        child: Builder(
          builder: (context) {
            // Get the current route's state and use its unique key
            final state = GoRouterState.of(context);
            // This is the common GoRouter pattern to correctly render nested content
            return KeyedSubtree(
              key: state.pageKey,
              child: state.,
            );
          },
        ),
      ),
      
      // --- Bottom Navigation Bar ---
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black54, 
              blurRadius: 10,
              offset: Offset(0, -2)
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: _onTap,
          
          // Aesthetic Settings:
          backgroundColor: navBarColor, 
          selectedItemColor: primaryPink, 
          unselectedItemColor: textColor.withOpacity(0.7), 
          type: BottomNavigationBarType.fixed, 
          showUnselectedLabels: false, 
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.explore_outlined), label: 'Explore'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
