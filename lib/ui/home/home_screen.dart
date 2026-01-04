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

    // The "Add" button is at index 2, but isn't a branch
    if (index == 2) {
      context.push('/create-post');
      return;
    }

    // Map UI icons to GoRouter branches
    // Branch 0: Explore, Branch 1: Activity/Chat, Branch 2: Profile
    switch (index) {
      case 0:
        navigationShell.goBranch(0);
        break;
      case 1:
        navigationShell.goBranch(1);
        break;
      case 4:
        navigationShell.goBranch(2);
        break;
      default:
        // Search (index 3) is currently a placeholder
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Maps the shell's internal index (0,1,2) back to the 5-item UI layout
    final currentIndex = switch (navigationShell.currentIndex) {
      0 => 0, // Explore Branch
      1 => 1, // Activity Branch
      2 => 4, // Profile Branch
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
                _buildNavItem(
                  0,
                  Icons.explore_rounded,
                  Icons.explore_outlined,
                  'Explore',
                  currentIndex,
                  context,
                ),
                
                // Real-time Chat/Activity Badge
                _buildLiveActivityNavItem(1, currentIndex, context),

                _buildCreateButton(context),

                _buildNavItem(
                  3,
                  Icons.search_rounded,
                  Icons.search_rounded,
                  'Search',
                  currentIndex,
                  context,
                ),

                _buildNavItem(
                  4,
                  Icons.person_rounded,
                  Icons.person_outline_rounded,
                  'Profile',
                  currentIndex,
                  context,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔔 LIVE ACTIVITY BADGE
  /// Listens to the 'notifications' collection for the current user
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
            _buildNavItem(
              index,
              Icons.notifications_rounded,
              Icons.notifications_none_rounded,
              'Activity',
              currentIndex,
              context,
            ),
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
                      unreadCount > 9 ? '9+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildNavItem(
    int index,
    IconData selectedIcon,
    IconData unselectedIcon,
    String label,
    int currentIndex,
    BuildContext context,
  ) {
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
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? primaryPink : textColor.withOpacity(0.4),
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}