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

  void _onTap(int index, BuildContext context) {
    HapticFeedback.mediumImpact();
    if (index == 2) {
      context.push('/create-post');
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
                _buildNavItem(0, Icons.explore_rounded, Icons.explore_outlined, 'Explore', currentIndex, context),
                
                // Real-time Chat Badge logic
                _buildChatNavItem(1, currentIndex, context),
                
                _buildCreateButton(context),
                
                _buildNavItem(3, Icons.search_rounded, Icons.search_rounded, 'Search', currentIndex, context),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, 'Profile', currentIndex, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Specialized Nav Item that listens to Firestore for unread messages
  Widget _buildChatNavItem(int index, int currentIndex, BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: uid)
          // You can add a 'hasUnread' field logic here later
          .snapshots(),
      builder: (context, snapshot) {
        bool hasUpdate = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            _buildNavItem(index, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Chats', currentIndex, context),
            if (hasUpdate)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  height: 8,
                  width: 8,
                  decoration: const BoxDecoration(color: primaryPink, shape: BoxShape.circle),
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
          boxShadow: [BoxShadow(color: primaryPink.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, String label, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => _onTap(index, context),
      child: SizedBox(
        width: MediaQuery.of(context).size.width / 5.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isSelected ? selectedIcon : unselectedIcon, color: isSelected ? primaryPink : textColor.withOpacity(0.4), size: 26),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isSelected ? primaryPink : textColor.withOpacity(0.4), fontSize: 10)),
          ],
        ),
      ),
    );
  }
}