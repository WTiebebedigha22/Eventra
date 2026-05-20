import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    required this.child,
    required this.navigationShell,
    super.key,
  });

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color primaryLight = Color(0xFF8B85FF);
  static const Color secondaryColor = Color(0xFF3F3D56);
  static const Color backgroundColor = Colors.white;
  static const Color inactiveColor = Color(0xFFA0A3BD);
  static const Color borderStroke = Color(0xFFEEF2F6);

  void _onTap(int index, BuildContext context) {
    HapticFeedback.selectionClick();

    if (index == 2) {
      context.push('/create-post');
      return;
    }

    switch (index) {
      case 0:
        navigationShell.goBranch(0);
        break;
      case 1:
        navigationShell.goBranch(1);
        break;
      case 3:
        navigationShell.goBranch(2);
        break;
      case 4:
        navigationShell.goBranch(4);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = switch (navigationShell.currentIndex) {
      0 => 0,
      1 => 1,
      2 => 3,
      4 => 4,
      _ => 0,
    };

    return Scaffold(
      backgroundColor: backgroundColor,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 75,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Home
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined,
                    currentIndex, context),
                // Messages
                _buildChatItem(1, currentIndex, context),
                // Create Post (centre FAB)
                _buildCreateButton(context),
                // Explore
                _buildNavItem(3, Icons.explore_rounded, Icons.explore_outlined,
                    currentIndex, context),
                // Profile
                _buildProfileItem(4, currentIndex, context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData selectedIcon, IconData unselectedIcon,
      int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index, context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  key: ValueKey(isSelected),
                  isSelected ? selectedIcon : unselectedIcon,
                  color: isSelected ? primaryColor : inactiveColor,
                  size: 26,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSelected ? 3 : 0,
                width: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatItem(int index, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index, context),
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      key: ValueKey(isSelected),
                      isSelected
                          ? Icons.chat_rounded
                          : Icons.chat_outlined,
                      color: isSelected ? primaryColor : inactiveColor,
                      size: 26,
                    ),
                  ),
                  // Unread message badge
                  StreamBuilder<QuerySnapshot>(
                    stream: uid != null
                        ? FirebaseFirestore.instance
                            .collectionGroup('messages')
                            .where('read', isEqualTo: false)
                            .where('recipientId', isEqualTo: uid)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      final count = snapshot.data?.docs.length ?? 0;
                      if (count == 0) return const SizedBox();
                      
                      return Positioned(
                        top: -4,
                        right: -8,
                        child: badges.Badge(
                          badgeContent: Text(
                            count > 99 ? '99+' : count.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          badgeStyle: badges.BadgeStyle(
                            badgeColor: Colors.redAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSelected ? 3 : 0,
                width: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileItem(int index, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    
    return Expanded(
      child: StreamBuilder<DocumentSnapshot>(
        stream: uid != null
            ? FirebaseFirestore.instance.collection('users').doc(uid).snapshots()
            : const Stream.empty(),
        builder: (context, snapshot) {
          String? photoURL;
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            photoURL = data?['photoURL'] as String?;
          }
          
          return InkWell(
            onTap: () => _onTap(index, context),
            highlightColor: Colors.transparent,
            splashColor: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isSelected ? primaryColor.withOpacity(0.08) : Colors.transparent,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: primaryColor, width: 2.5)
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: isSelected ? primaryColor : inactiveColor,
                      backgroundImage: photoURL != null && photoURL.isNotEmpty
                          ? NetworkImage(photoURL)
                          : null,
                      child: (photoURL == null || photoURL.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 16,
                              color: isSelected ? Colors.white : Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isSelected ? 3 : 0,
                    width: isSelected ? 24 : 0,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCreateButton(BuildContext context) {
    return Expanded(
      child: Center(
        child: GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            _onTap(2, context);
          },
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryColor, primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ),
      ),
    );
  }
}

// Alternative: If you prefer a simpler notification badge without the package
class SimpleNotificationBadgeItem extends StatelessWidget {
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const SimpleNotificationBadgeItem({
    required this.index,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                children: [
                  Icon(
                    isSelected
                        ? Icons.chat_rounded
                        : Icons.chat_outlined,
                    color: isSelected ? HomeScreen.primaryColor : HomeScreen.inactiveColor,
                    size: 26,
                  ),
                  StreamBuilder<QuerySnapshot>(
                    stream: uid != null
                        ? FirebaseFirestore.instance
                            .collection('notifications')
                            .where('recipientId', isEqualTo: uid)
                            .where('read', isEqualTo: false)
                            .snapshots()
                        : const Stream.empty(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const SizedBox();
                      }

                      final count = snapshot.data!.docs.length;
                      final displayCount = count > 99 ? '99+' : count.toString();

                      return Positioned(
                        top: -4,
                        right: -8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            displayCount,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isSelected ? 3 : 0,
                width: isSelected ? 24 : 0,
                decoration: BoxDecoration(
                  color: HomeScreen.primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}