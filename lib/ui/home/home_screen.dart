import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    required this.child,
    required this.navigationShell,
    super.key,
  });

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Color(0xFF0F0F0F);
  static const Color navBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;
  static const Color borderColor = Color(0xFF262626);

  /// Handles navigation logic and haptics
  void _onTap(int index, BuildContext context) {
    HapticFeedback.lightImpact();

    // Index 2 is the "Add" floating button - pushes a full-screen route
    if (index == 2) {
      context.push('/create-post');
      return;
    }

    // Mapping UI indexes to GoRouter branch indexes
    // Ensure your router.dart matches these branch numbers!
    switch (index) {
      case 0:
        navigationShell.goBranch(0); // Explore
        break;
      case 1:
        navigationShell.goBranch(1); // Activity/Chat
        break;
      case 3:
        navigationShell.goBranch(3); // Search Branch (New)
        break;
      case 4:
        navigationShell.goBranch(2); // Profile Branch (Branch 2 in shell)
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maps the shell's internal branch index back to the 5-item UI layout index
    final currentIndex = switch (navigationShell.currentIndex) {
      0 => 0, // Explore
      1 => 1, // Activity
      3 => 3, // Search
      2 => 4, // Profile (Branch 2 corresponds to UI index 4)
      _ => 0,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: navBarColor,
          border: Border(top: BorderSide(color: borderColor, width: 0.5)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home', currentIndex, context),
                
                _buildLiveActivityNavItem(1, currentIndex, context),

                _buildCreateButton(context),

                _buildNavItem(3, Icons.search_rounded, Icons.search_outlined, 'Search', currentIndex, context),

                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile', currentIndex, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI COMPONENTS ---

  Widget _buildLiveActivityNavItem(int index, int currentIndex, BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('notifications')
          .where('userId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .snapshots(),
      builder: (context, snapshot) {
        final int unreadCount = snapshot.hasData ? snapshot.data!.docs.length : 0;
        final bool hasUpdate = unreadCount > 0;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildNavItem(index, Icons.messenger_rounded, Icons.messenger_outline_rounded, 'Messages', currentIndex, context),
            if (hasUpdate)
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: primaryPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: navBarColor, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(2, context),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: primaryPink,
          borderRadius: BorderRadius.circular(16), // Slightly more modern curve
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
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected ? primaryPink : textColor.withOpacity(0.4),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}