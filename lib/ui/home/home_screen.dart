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

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color inactiveColor = Color(0xFFBDC3C7);
  static const Color borderStroke = Color(0xFFF1F3F5);

  void _onTap(int index, BuildContext context) {
    HapticFeedback.selectionClick(); // Use selectionClick for nav feedback

    if (index == 2) {
      context.push('/create-post');
      return;
    }

    // Index mapping for GoRouter branches
    switch (index) {
      case 0: navigationShell.goBranch(0); break; // Home
      case 1: navigationShell.goBranch(1); break; // Messages
      case 3: navigationShell.goBranch(3); break; // Search
      case 4: navigationShell.goBranch(2); break; // Profile
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current UI active index calculation
    final currentIndex = switch (navigationShell.currentIndex) {
      0 => 0,
      1 => 1,
      3 => 3,
      2 => 4,
      _ => 0,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: backgroundColor,
          border: Border(top: BorderSide(color: borderStroke, width: 1.5)),
        ),
        child: SafeArea(
          child: Container(
            height: 65,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, currentIndex, context),
                const NotificationBadgeItem(index: 1), // Optimized Stream component
                _buildCreateButton(context),
                _buildNavItem(3, Icons.search_rounded, Icons.search_outlined, currentIndex, context),
                _buildNavItem(4, Icons.person_rounded, Icons.person_outline_rounded, currentIndex, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index, context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Icon(
          isSelected ? selectedIcon : unselectedIcon,
          color: isSelected ? primaryColor : inactiveColor,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTap(2, context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 28),
        ),
      ),
    );
  }
}

/// Extracted Component to prevent full Nav rebuilds on database updates
class NotificationBadgeItem extends StatelessWidget {
  final int index;
  const NotificationBadgeItem({required this.index, super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final parent = context.findAncestorWidgetOfExactType<HomeScreen>();
    
    // Calculate if this item is selected via the navigation shell
    final shell = parent?.navigationShell;
    final isSelected = shell?.currentIndex == 1;

    return Expanded(
      child: InkWell(
        onTap: () => parent?._onTap(1, context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              isSelected ? Icons.messenger_rounded : Icons.messenger_outline_rounded,
              color: isSelected ? HomeScreen.primaryColor : HomeScreen.inactiveColor,
              size: 26,
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('notifications')
                  .where('userId', isEqualTo: uid)
                  .where('isRead', isEqualTo: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox();
                
                return Positioned(
                  top: 12,
                  right: MediaQuery.of(context).size.width * 0.04,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    constraints: const BoxConstraints(minWidth: 16),
                    child: Text(
                      '${snapshot.data!.docs.length}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}