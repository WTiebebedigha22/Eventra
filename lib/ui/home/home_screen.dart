import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 💡 Must be StatelessWidget when used with StatefulShellRoute
class HomeScreen extends StatelessWidget {
  // 1. Accepts the content provided by the router (the active branch)
  final Widget child;
  // 2. Accepts the shell context to manage navigation between branches
  final StatefulNavigationShell? navigationShell;

  const HomeScreen({
    required this.child, 
    required this.navigationShell, 
    super.key
  });

  // Define your color scheme (consistent)
  static const Color primaryPink = Color(0xFFE91E63); 
  static const Color backgroundColor = Colors.black;
  static const Color navBarColor = Color(0xFF181818); 
  static const Color textColor = Colors.white;

  // 3. Navigation method using the Shell
  void _onTap(int index) {
    // Uses the shell's built-in navigation to switch branches
    navigationShell?.goBranch(
      index,
      // Reset the stack of the current branch if we tap the current tab again
      initialLocation: index == navigationShell?.currentIndex, 
    );
  }

  @override
  Widget build(BuildContext context) {
    // 4. Get the current index directly from the shell
    final currentIndex = navigationShell?.currentIndex ?? 0;

    return Scaffold(
      backgroundColor: backgroundColor,
      
      // --- FIXED BODY ---
      // The body directly renders the child widget (the active screen)
      body: SafeArea(
        child: child,
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
          onTap: _onTap, // Uses the fixed _onTap
          
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