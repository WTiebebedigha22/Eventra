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

  /// ✅ FIXED NAVIGATION LOGIC
  void _onTap(int index, BuildContext context) {
    HapticFeedback.mediumImpact();

    // Create Post (center button)
    if (index == 2) {
      context.push('/create-post');
      return;
    }

    switch (index) {
      case 0: // Explore
        navigationShell.goBranch(0);
        break;

      case 1: // Chat
        navigationShell.goBranch(1);
        break;

      case 4: // Profile
        navigationShell.goBranch(2);
        break;

      default:
        // Search tab not implemented yet
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    /// ✅ FIXED SELECTED INDEX MAPPING
    final currentIndex = switch (navigationShell.currentIndex) {
      0 => 0, // Explore
      1 => 1, // Chat
      2 => 4, // Profile
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

                /// Chat with realtime badge
                _buildChatNavItem(1, currentIndex, context),

                _buildCreateButton(context),

                /// Search (inactive for now)
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

  /// 🔔 CHAT BADGE
  Widget _buildChatNavItem(int index, int currentIndex, BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          .snapshots(),
      builder: (context, snapshot) {
        final hasUpdate = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildNavItem(
              index,
              Icons.chat_bubble_rounded,
              Icons.chat_bubble_outline_rounded,
              'Chats',
              currentIndex,
              context,
            ),
            if (hasUpdate)
              const Positioned(
                top: 12,
                right: 12,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: primaryPink,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(width: 8, height: 8),
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
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? selectedIcon : unselectedIcon,
              color: isSelected
                  ? primaryPink
                  : textColor.withOpacity(0.4),
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? primaryPink
                    : textColor.withOpacity(0.4),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
