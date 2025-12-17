import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    required this.child,
    required this.navigationShell,
    super.key,
  });

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color navBarColor = Color(0xFF121212);
  static const Color textColor = Colors.white;
  static const Color borderColor = Color(0xFF262626);

  static const String createPostRoute = '/create-post';

  void _onTap(int index, BuildContext context) {
    HapticFeedback.selectionClick();
    
    // logic: index 2 is "Create" which is a full-screen route, not a branch
    if (index == 2) {
      context.go(createPostRoute);
    } else {
      // Re-map the visual index to the branch index
      // Tab 0 -> Branch 0 (Explore)
      // Tab 1 -> Branch 1 (Chats)
      // Tab 3 -> Branch 2 (Search)
      // Tab 4 -> Branch 3 (Profile)
      int branchIndex = index > 2 ? index - 1 : index;

      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Convert current branch index back to visual tab index for highlighting
    final currentBranchIndex = navigationShell.currentIndex;
    final currentIndex = currentBranchIndex >= 2 ? currentBranchIndex + 1 : currentBranchIndex;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(color: borderColor, height: 1, thickness: 1),
          Container(
            padding: const EdgeInsets.only(top: 12, bottom: 24),
            color: navBarColor,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, 'Explore', currentIndex, context),
                _buildNavItem(1, Icons.message_outlined, 'Chats', currentIndex, context),
                _buildNavItem(2, Icons.add_circle_outline_rounded, 'Create', currentIndex, context),
                _buildNavItem(3, Icons.search_rounded, 'Search', currentIndex, context),
                _buildNavItem(4, Icons.person_2_outlined, 'Profile', currentIndex, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTap(index, context),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? primaryPink : textColor.withOpacity(0.5),
              size: 24, // Slightly smaller to accommodate 5 items
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryPink : textColor.withOpacity(0.5),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              height: 4,
              width: 4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? primaryPink : Colors.transparent,
              ),
            )
          ],
        ),
      ),
    );
  }
}