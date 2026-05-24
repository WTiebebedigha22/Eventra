import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  String _currentUid = '';
  
  late AnimationController _fadeController;
  final Map<String, Map<String, dynamic>> _profileCache = {};
  
  Stream<QuerySnapshot>? _onlineUsersStream;
  int _onlineCount = 0;
  bool _isInitialized = false;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    // Clean the current UID
    _currentUid = _currentUid.split('_').first;
    print('Current user UID (cleaned): $_currentUid');
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    
    _onlineUsersStream = FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
        
    if (_currentUid.isNotEmpty) {
      _setUserOnlineStatus(true);
      _isInitialized = true;
    }
    
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null && _currentUid != user.uid) {
        _setUserOnlineStatus(false);
        _currentUid = user.uid!.split('_').first;
        _setUserOnlineStatus(true);
        if (mounted) {
          setState(() {});
        }
      }
    });
    
    // Start animation after initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _fadeController.forward();
      }
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (!_isInitialized) return;
    
    if (state == AppLifecycleState.resumed) {
      _setUserOnlineStatus(true);
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.detached) {
      _setUserOnlineStatus(false);
    }
  }
  
  Future<void> _setUserOnlineStatus(bool isOnline) async {
    if (_currentUid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_currentUid.isNotEmpty) {
      _setUserOnlineStatus(false);
    }
    _fadeController.dispose();
    super.dispose();
  }

  // Extract other user ID from chat data
  String _getOtherUserId(Map<String, dynamic> chatData) {
    final participants = chatData['participants'] as List<dynamic>?;
    
    if (participants == null || participants.isEmpty) {
      return '';
    }
    
    for (final participant in participants) {
      final String participantStr = participant.toString();
      // Skip the current user
      if (participantStr != _currentUid) {
        return participantStr;
      }
    }
    
    return '';
  }

  Future<Map<String, dynamic>?> _getProfile(String uid) async {
    if (uid.isEmpty) return null;
    
    if (_profileCache.containsKey(uid)) {
      return _profileCache[uid];
    }
    
    try {
      print('Fetching user profile for UID: $uid');
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final userData = doc.data();
        print('User found: ${userData?['displayName']}');
        _profileCache[uid] = userData!;
        return userData;
      } else {
        print('User not found for UID: $uid');
        return null;
      }
    } catch (e) {
      debugPrint('Error getting profile for $uid: $e');
      return null;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return '';
    
    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else if (timestamp is DateTime) {
      date = timestamp;
    } else {
      return '';
    }
    
    final now = DateTime.now();
    final diff = now.difference(date);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w';
    return DateFormat('MMM d').format(date);
  }

  String _truncateText(String text, int maxLength) {
    if (text.isEmpty) return '';
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUid.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Please log in to view messages'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                ),
                child: const Text('Sign In'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }

          if (snapshot.hasError) {
            print('Error loading chats: ${snapshot.error}');
            return _buildError(snapshot.error.toString());
          }

          final docs = snapshot.data?.docs ?? [];
          
          if (docs.isEmpty) {
            return _buildEmptyState();
          }

          // Group by other user ID and keep only the most recent
          final Map<String, QueryDocumentSnapshot> uniqueChats = {};
          
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final otherId = _getOtherUserId(data);
            
            if (otherId.isEmpty) continue;
            
            if (!uniqueChats.containsKey(otherId)) {
              uniqueChats[otherId] = doc;
            } else {
              // Keep the most recent chat
              final existing = uniqueChats[otherId]!.data() as Map<String, dynamic>;
              final existingTime = existing['updatedAt'] as Timestamp?;
              final newTime = data['updatedAt'] as Timestamp?;
              
              if (newTime != null && (existingTime == null || newTime.toDate().isAfter(existingTime.toDate()))) {
                uniqueChats[otherId] = doc;
              }
            }
          }

          final uniqueChatsList = uniqueChats.values.toList();
          
          if (uniqueChatsList.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: uniqueChatsList.length,
              itemBuilder: (context, index) {
                final doc = uniqueChatsList[index];
                final data = doc.data() as Map<String, dynamic>;
                final otherId = _getOtherUserId(data);
                
                // Get unread count
                int unread = 0;
                if (data['unreadCounts'] != null) {
                  unread = (data['unreadCounts'][_currentUid] as int?) ?? 0;
                }
                
                final isMe = data['lastSenderId'] == _currentUid;
                final lastMessage = data['lastMessage'] ?? '';
                final lastMessageTime = data['updatedAt'] as Timestamp?;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _getProfile(otherId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return _buildSkeletonTile();
                    }
                    
                    if (userSnapshot.hasError || userSnapshot.data == null) {
                      return _buildErrorTile(() {
                        setState(() {
                          _profileCache.remove(otherId);
                        });
                      });
                    }
                    
                    final userData = userSnapshot.data!;
                    final name = userData['displayName'] ?? 
                                 userData['username'] ?? 
                                 'User';
                    final avatar = userData['photoURL'] as String?;
                    
                    return _ChatTile(
                      chatId: doc.id,
                      userName: name,
                      userAvatar: avatar,
                      lastMessage: lastMessage,
                      lastMessageTime: lastMessageTime,
                      unread: unread,
                      isMe: isMe,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _chatService.markAsRead(doc.id);
                        context.push(
                          '/chat/${doc.id}',
                          extra: {'otherUserName': name, 'otherAvatar': avatar},
                        );
                      },
                      onDismiss: () => _chatService.deleteConversation(doc.id),
                      formatTimestamp: _formatTimestamp,
                      truncateText: _truncateText,
                    );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 14,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 180,
                  height: 12,
                  color: Colors.grey.shade200,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorTile(VoidCallback onRetry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 26,
            backgroundColor: Colors.red,
            child: Icon(Icons.error, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Failed to load user',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: onRetry,
                  child: Text(
                    'Tap to retry',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: backgroundColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        "Messages",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 28,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        if (_currentUid.isNotEmpty)
          StreamBuilder<QuerySnapshot>(
            stream: _onlineUsersStream,
            builder: (context, snapshot) {
              final count = snapshot.data?.docs.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: count > 0 ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$count online',
                        style: TextStyle(
                          fontSize: 12,
                          color: count > 0 ? Colors.green.shade700 : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: 6,
      itemBuilder: (_, index) => _buildSkeletonTile(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "No conversations yet",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Start chatting with someone",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.push('/explore'),
            icon: const Icon(Icons.explore),
            label: const Text('Find People to Chat With'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            const Text(
              "Couldn't load messages",
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => setState(() {}),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String chatId;
  final String userName;
  final String? userAvatar;
  final String lastMessage;
  final Timestamp? lastMessageTime;
  final int unread;
  final bool isMe;
  final VoidCallback onTap;
  final VoidCallback onDismiss;
  final String Function(dynamic) formatTimestamp;
  final String Function(String, int) truncateText;

  const _ChatTile({
    required this.chatId,
    required this.userName,
    this.userAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unread,
    required this.isMe,
    required this.onTap,
    required this.onDismiss,
    required this.formatTimestamp,
    required this.truncateText,
  });

  static const Color primaryColor = Color(0xFF6C63FF);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(chatId),
      direction: DismissDirection.endToStart,
      background: _buildDismissBackground(),
      confirmDismiss: (_) => _confirmDelete(context),
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: unread > 0
                ? Border.all(color: primaryColor.withOpacity(0.3), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              _buildAvatar(),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF1A1A2E),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatTimestamp(lastMessageTime),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                            color: unread > 0 ? primaryColor : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildPreview(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 26,
      backgroundColor: primaryColor.withOpacity(0.1),
      backgroundImage: userAvatar != null && userAvatar!.isNotEmpty 
          ? CachedNetworkImageProvider(userAvatar!) 
          : null,
      child: userAvatar == null || userAvatar!.isEmpty
          ? Icon(Icons.person, color: primaryColor, size: 28)
          : null,
    );
  }

  Widget _buildPreview() {
    String msg = lastMessage;
    msg = truncateText(msg, 40); // Truncate to prevent overflow
    
    final bool isImage = msg.contains('📷') || msg.contains('[image]') || msg.contains('📸');
    final bool isAudio = msg.contains('🎵') || msg.contains('[audio]') || msg.contains('🎤');

    return Row(
      children: [
        if (isMe)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.done_all_rounded,
              size: 14,
              color: unread > 0 ? primaryColor.withOpacity(0.7) : Colors.grey.shade400,
            ),
          ),
        if (isImage)
          const Icon(Icons.image_rounded, size: 15, color: Colors.grey),
        if (isAudio)
          const Icon(Icons.mic_rounded, size: 15, color: Colors.grey),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            msg.isEmpty
                ? "Start a conversation…"
                : isImage
                    ? "📷 Photo"
                    : isAudio
                        ? "🎵 Voice message"
                        : msg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unread > 0 ? const Color(0xFF1A1A2E) : Colors.grey[500],
              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDismissBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.redAccent, Colors.red],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_rounded, color: Colors.white, size: 24),
          SizedBox(height: 4),
          Text('Delete', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete conversation?"),
        content: const Text("This conversation will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}