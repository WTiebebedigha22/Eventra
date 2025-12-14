import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

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

  // Define the Route for Create Post
  static const String createPostRoute = '/create-post';

  void _onTap(int index, BuildContext context) {
    // Check if the user tapped the 'Create Post' index (1)
    if (index == 1) {
      // Navigate using context.go() to open the creation screen full-screen, 
      // outside the StatefulShellRoute's tab history.
      context.go(createPostRoute);
    } else {
      // For the other tabs (0, 2, 3), determine the corresponding branch index
      // Tab Index 0 -> Branch 0
      // Tab Index 2 -> Branch 1
      // Tab Index 3 -> Branch 2
      final branchIndex = index > 1 ? index - 1 : index;

      navigationShell.goBranch(
        branchIndex,
        // Reset the stack of the current branch if we tap the current tab again
        initialLocation: branchIndex == navigationShell.currentIndex, 
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 4. Get the current branch index directly from the shell
    final currentBranchIndex = navigationShell.currentIndex;
    
    // Convert the current GoRouter branch index back to the BottomNavigationBar index
    // Branch Index 0 -> Tab Index 0
    // Branch Index 1 -> Tab Index 2
    // Branch Index 2 -> Tab Index 3
    final currentIndex = currentBranchIndex > 0 ? currentBranchIndex + 1 : currentBranchIndex;


    return Scaffold(
      backgroundColor: backgroundColor,
      
      // --- FIXED BODY ---
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
          // Use the updated _onTap that takes context
          onTap: (index) => _onTap(index, context), 
          
          // Aesthetic Settings:
          backgroundColor: navBarColor, 
          selectedItemColor: primaryPink, 
          unselectedItemColor: textColor.withOpacity(0.7), 
          type: BottomNavigationBarType.fixed, 
          showUnselectedLabels: false, 
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.explore_outlined), label: 'Explore'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_box_outlined), label: 'Create'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chats'),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}