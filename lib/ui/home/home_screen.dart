import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomeScreen extends StatelessWidget {
  final Widget child;
  final StatefulNavigationShell navigationShell;

  const HomeScreen({
    required this.child,
    required this.navigationShell,
    super.key,
  });

  static const Color primaryColor = Color(0xFF6C63FF);
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
        decoration: const BoxDecoration(
          color: backgroundColor,
          border: Border(
            top: BorderSide(color: borderStroke, width: 1),
          ),
        ),
        child: SafeArea(
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Home
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined,
                    currentIndex, context),
                // Messages (Chat with unread count)
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
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? selectedIcon : unselectedIcon,
                color: isSelected ? primaryColor : inactiveColor,
                size: 26,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 20,
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

  // IMPLEMENTED: Chat item with real unread message count
  Widget _buildChatItem(int index, int currentIndex, BuildContext context) {
    final isSelected = currentIndex == index;
    final String? currentUid = FirebaseAuth.instance.currentUser?.uid;
    
    if (currentUid == null || currentUid.isEmpty) {
      return _buildSimpleChatItem(isSelected, index, context);
    }
    
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: currentUid)
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, chatsSnapshot) {
          if (!chatsSnapshot.hasData || chatsSnapshot.data == null) {
            return _buildSimpleChatItem(isSelected, index, context);
          }
          
          // Stream to calculate total unread count
          return StreamBuilder<int>(
            stream: _getTotalUnreadCount(chatsSnapshot.data!.docs, currentUid),
            builder: (context, unreadSnapshot) {
              final int unreadCount = unreadSnapshot.data ?? 0;
              
              return InkWell(
                onTap: () => _onTap(index, context),
                highlightColor: Colors.transparent,
                splashColor: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected ? Icons.chat_rounded : Icons.chat_outlined,
                            color: isSelected ? primaryColor : inactiveColor,
                            size: 24,
                          ),
                          if (isSelected)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              height: 3,
                              width: 20,
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 16),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // Helper stream to calculate total unread messages
  Stream<int> _getTotalUnreadCount(List<QueryDocumentSnapshot> chats, String currentUid) {
    final StreamController<int> controller = StreamController<int>.broadcast();
    
    Future<void> calculateTotal() async {
      int total = 0;
      for (final chatDoc in chats) {
        final String chatId = chatDoc.id;
        try {
          final QuerySnapshot unreadMessages = await FirebaseFirestore.instance
              .collection('chats')
              .doc(chatId)
              .collection('messages')
              .where('read', isEqualTo: false)
              .where('senderId', isNotEqualTo: currentUid)
              .get();
          
          total += unreadMessages.docs.length;
        } catch (e) {
          // Skip this chat if error
          print('Error counting unread for chat $chatId: $e');
        }
      }
      if (!controller.isClosed) {
        controller.add(total);
      }
    }
    
    // Calculate initial total
    calculateTotal();
    
    // Listen to changes in all chats' messages
    for (final chatDoc in chats) {
      final String chatId = chatDoc.id;
      FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('read', isEqualTo: false)
          .where('senderId', isNotEqualTo: currentUid)
          .snapshots()
          .listen((snapshot) {
            calculateTotal(); // Recalculate when any message changes
          });
    }
    
    return controller.stream;
  }

  Widget _buildSimpleChatItem(bool isSelected, int index, BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index, context),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? Icons.chat_rounded : Icons.chat_outlined,
                color: isSelected ? primaryColor : inactiveColor,
                size: 24,
              ),
              if (isSelected)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  height: 3,
                  width: 20,
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
    final String? uid = FirebaseAuth.instance.currentUser?.uid;
    
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
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: primaryColor, width: 2)
                          : null,
                    ),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: isSelected ? primaryColor : inactiveColor,
                      backgroundImage: photoURL != null && photoURL.isNotEmpty
                          ? CachedNetworkImageProvider(photoURL)
                          : null,
                      child: (photoURL == null || photoURL.isEmpty)
                          ? Icon(
                              Icons.person,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.white70,
                            )
                          : null,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      height: 3,
                      width: 20,
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
      child: GestureDetector(
        onTap: () => _onTap(2, context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 12,
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