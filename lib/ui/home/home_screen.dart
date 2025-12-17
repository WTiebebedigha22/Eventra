import 'dart:ui';
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

  // Eventra Premium Color Palette
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFF0F0F0F); // Deeper black
  static const Color navBarColor = Color(0xFF181818); // Elevated surface
  static const Color textColor = Colors.white;
  static const Color borderColor = Color(0xFF262626);

  static const String createPostRoute = '/create-post';

  void _onTap(int index, BuildContext context) {
    HapticFeedback.mediumImpact(); // More premium feedback
    
    if (index == 2) {
      context.push(createPostRoute); // Use push to keep nav bar visible or overlay
    } else {
      int branchIndex = index > 2 ? index - 1 : index;
      navigationShell.goBranch(
        branchIndex,
        initialLocation: branchIndex == navigationShell.currentIndex,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentBranchIndex = navigationShell.currentIndex;
    final currentIndex = currentBranchIndex >= 2 ? currentBranchIndex + 1 : currentBranchIndex;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      // Stack used to give the nav bar a slight "floating" or glass feel if desired
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: navBarColor,
          border: Border(
            top: BorderSide(color: borderColor, width: 0.5),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Container(
            height: 70, // Fixed height for a cleaner look
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.explore_rounded, Icons.explore_outlined, 'Explore', currentIndex, context),
                _buildNavItem(1, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chats', currentIndex, context),
                _buildCreateButton(context), // Special central button
                _buildNavItem(3, Icons.search_rounded, Icons.search_rounded, 'Search', currentIndex, context),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile', currentIndex, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Modern Central Action Button
  Widget _buildCreateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(2, context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryPink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: primaryPink.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    
    return InkWell(
      onTap: () => _onTap(index, context),
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5.5, 
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryPink : textColor.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryPink : textColor.withOpacity(0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 4),
            // Animated indicator bar instead of just a dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isSelected ? 12 : 0,
              decoration: BoxDecoration(
                color: primaryPink,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          ],
        ),
      ),
    );
  }
}