import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

import '../../models/chat/chat_session.dart';
import '../../services/chat_service.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ChatService _chatService = ChatService();
  final String _currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';
  
  late AnimationController _fadeController;
  final Map<String, Future<Map<String, dynamic>?>> _profileCache = {};
  
  // Track online users count
  Stream<QuerySnapshot>? _onlineUsersStream;
  int _onlineCount = 0;

  Future<Map<String, dynamic>?> _getProfile(String uid) {
    return _profileCache.putIfAbsent(uid, () => _chatService.getUserProfile(uid));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..forward();
    
    // Initialize online users stream
    _onlineUsersStream = FirebaseFirestore.instance
        .collection('users')
        .where('isOnline', isEqualTo: true)
        .snapshots();
        
    // Set user as online when app starts
    _setUserOnlineStatus(true);
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
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
    _setUserOnlineStatus(false);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F5FB),
      appBar: _buildAppBar(),
      body: StreamBuilder<QuerySnapshot>(
        stream: _chatService.getConversationsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmer();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error.toString());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final sessions = snapshot.data!.docs
              .map((d) => ChatSession.fromFirestore(d))
              .toList();

          return FadeTransition(
            opacity: _fadeController,
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {});
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: sessions.length,
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  final otherId = session.getOtherUserId(_currentUid);
                  final unread = session.unreadFor(_currentUid);
                  final isMe = session.lastMessageSenderId == _currentUid;

                  return _ChatTile(
                    key: ValueKey(session.id),
                    session: session,
                    profileFuture: _getProfile(otherId),
                    currentUid: _currentUid,
                    otherId: otherId,
                    unread: unread,
                    isMe: isMe,
                    index: index,
                    onTap: (name, avatar) {
                      HapticFeedback.lightImpact();
                      _chatService.markAsRead(session.id);
                      context.push(
                        '/chat/room/${session.id}/$otherId',
                        extra: {'peerName': name, 'peerAvatar': avatar},
                      );
                    },
                    onDismiss: () => _chatService.deleteConversation(session.id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF6F5FB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: 20,
      title: const Text(
        "Messages",
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 26,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
      actions: [
        StreamBuilder<QuerySnapshot>(
          stream: _onlineUsersStream,
          builder: (context, snapshot) {
            final count = snapshot.data?.docs.length ?? 0;
            // Update count for animation
            if (_onlineCount != count && mounted) {
              setState(() => _onlineCount = count);
            }
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
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: count > 0 ? Colors.green : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
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
      itemBuilder: (_, index) => _ShimmerTile(delay: index * 80),
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
              color: Colors.deepPurpleAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 40,
              color: Colors.deepPurpleAccent,
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
            onPressed: () => context.push('/discover'),
            icon: const Icon(Icons.explore),
            label: const Text('Find People to Chat With'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurpleAccent,
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
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatTile extends StatefulWidget {
  final ChatSession session;
  final Future<Map<String, dynamic>?> profileFuture;
  final String currentUid;
  final String otherId;
  final int unread;
  final bool isMe;
  final int index;
  final void Function(String name, String? avatar) onTap;
  final VoidCallback onDismiss;

  const _ChatTile({
    super.key,
    required this.session,
    required this.profileFuture,
    required this.currentUid,
    required this.otherId,
    required this.unread,
    required this.isMe,
    required this.index,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends State<_ChatTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;
  final ChatService _chatService = ChatService();
  
  // FIX: Cache user data to prevent "Bad State" error
  Map<String, dynamic>? _cachedUserData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 350 + widget.index * 40),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 50), () {
      if (mounted) _slideController.forward();
    });
    
    // Load user profile
    _loadUserProfile();
  }
  
  Future<void> _loadUserProfile() async {
    try {
      final userData = await widget.profileFuture;
      if (mounted) {
        setState(() {
          _cachedUserData = userData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Dismissible(
          key: ValueKey(widget.session.id),
          direction: DismissDirection.endToStart,
          background: _dismissBg(),
          confirmDismiss: (_) => _confirmDelete(context),
          onDismissed: (_) => widget.onDismiss(),
          child: _buildContent(),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    // Show loading state while fetching profile
    if (_isLoading) {
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
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
    
    final user = _cachedUserData;
    final name = user?['displayName'] ?? 'User';
    final avatar = user?['photoURL'] as String?;
    
    // FIX: Proper error handling for user document stream
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherId)
          .snapshots()
          .handleError((error) {
            debugPrint('User stream error: $error');
            return Stream.value(null);
          }),
      builder: (context, userSnap) {
        // FIX: Prevent "Bad State" error by checking existence properly
        Map<String, dynamic>? userData;
        bool isOnline = false;
        bool isTyping = false;
        
        if (userSnap.hasData && userSnap.data != null && userSnap.data!.exists) {
          try {
            userData = userSnap.data!.data() as Map<String, dynamic>?;
            isOnline = userData?['isOnline'] as bool? ?? false;
            isTyping = userData?['typingTo'] == widget.currentUid;
          } catch (e) {
            debugPrint('Error parsing user data: $e');
          }
        }

        return _buildTile(name, avatar, isOnline, isTyping);
      },
    );
  }

  Widget _buildTile(String name, String? avatar, bool isOnline, bool isTyping) {
    return GestureDetector(
      onTap: () => widget.onTap(name, avatar),
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
          border: widget.unread > 0
              ? Border.all(
                  color: Colors.deepPurpleAccent.withOpacity(0.25), 
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            _buildAvatar(avatar, isOnline),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontWeight: widget.unread > 0
                                ? FontWeight.w800
                                : FontWeight.w600,
                            fontSize: 15,
                            color: const Color(0xFF1A1A2E),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _chatService.formatTimestamp(widget.session.lastMessageTime as Timestamp?),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: widget.unread > 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                          color: widget.unread > 0
                              ? Colors.deepPurpleAccent
                              : Colors.grey[400],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: isTyping
                            ? const _TypingIndicator()
                            : _buildPreview(),
                      ),
                      if (widget.unread > 0) ...[
                        const SizedBox(width: 8),
                        _buildBadge(),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(String? avatar, bool isOnline) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.deepPurpleAccent.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 26,
            backgroundColor: Colors.deepPurple.shade50,
            backgroundImage: avatar != null && avatar.isNotEmpty 
                ? NetworkImage(avatar) 
                : null,
            child: avatar == null || avatar.isEmpty
                ? const Icon(Icons.person, color: Colors.deepPurpleAccent, size: 28)
                : null,
          ),
        ),
        if (isOnline)
          Positioned(
            bottom: 1,
            right: 1,
            child: Container(
              height: 13,
              width: 13,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPreview() {
    final msg = widget.session.lastMessage;
    final isImage = msg.contains('📷') || msg.contains('[image]') || msg.contains('📸');
    final isAudio = msg.contains('🎵') || msg.contains('[audio]') || msg.contains('🎤');

    return Row(
      children: [
        if (widget.isMe)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.done_all_rounded,
              size: 14,
              color: widget.unread > 0 
                  ? Colors.deepPurpleAccent.withOpacity(0.7)
                  : Colors.grey.shade400,
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
              color: widget.unread > 0
                  ? const Color(0xFF1A1A2E)
                  : Colors.grey[500],
              fontWeight: widget.unread > 0
                  ? FontWeight.w500
                  : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBadge() {
    return Container(
      constraints: const BoxConstraints(minWidth: 20),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.deepPurpleAccent, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        widget.unread > 99 ? '99+' : '${widget.unread}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _dismissBg() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
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
          Text(
            'Delete',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete conversation?",
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text("This conversation will be permanently deleted."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Delete",
                style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator();

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 400),
      ),
    );
    _anims = _controllers
        .map((c) => Tween<double>(begin: 0, end: -5).animate(
            CurvedAnimation(parent: c, curve: Curves.easeInOut),
          ))
        .toList();

    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat(reverse: true);
        }
      });
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          "typing",
          style: TextStyle(
            fontSize: 13,
            color: Colors.deepPurpleAccent.withOpacity(0.8),
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: const BoxDecoration(
                  color: Colors.deepPurpleAccent,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _ShimmerTile extends StatefulWidget {
  final int delay;
  const _ShimmerTile({required this.delay});

  @override
  State<_ShimmerTile> createState() => _ShimmerTileState();
}

class _ShimmerTileState extends State<_ShimmerTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _anim = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _controller.repeat();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final shimmerOffset = _anim.value;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              _shimmerCircle(52, shimmerOffset),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _shimmerBox(120, 14, shimmerOffset),
                        _shimmerBox(40, 10, shimmerOffset),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _shimmerBox(200, 12, shimmerOffset),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double width, double height, double offset) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [offset - 0.2, offset, offset + 0.2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  Widget _shimmerCircle(double size, double offset) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
          stops: [offset - 0.2, offset, offset + 0.2],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        shape: BoxShape.circle,
      ),
    );
  }
}