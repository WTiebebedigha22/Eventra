import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/chat_provider.dart';
import '../../models/chat/chat_message.dart';

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserProfilePic;

  const ChatRoomScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    this.otherUserName = "User",
    this.otherUserProfilePic,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  // ── Stream cached here so rebuilds (e.g. _hasText setState) don't
  //    re-create a new Firestore listener on every frame.
  late final Stream<List<ChatMessage>> _messageStream;
  StreamSubscription<List<ChatMessage>>? _chatSub;

  File? _selectedImage;
  bool _hasText = false;

  static const Color _purple = Color(0xFF6C4EF2);
  static const Color _purpleLight = Color(0xFFEDE9FD);
  static const Color _bg = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_handleTextChange);

    // Obtain provider once and cache the stream.
    final provider = Provider.of<ChatProvider>(context, listen: false);
    _messageStream = provider.loadChat(widget.chatId);

    // Keep a subscription so we can cancel it cleanly on dispose.
    _chatSub = _messageStream.listen((_) {});
  }

  void _handleTextChange() {
    final hasText = _ctrl.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    _chatSub?.cancel();
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendMessage(ChatProvider provider) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final imageFile = _selectedImage;
    _ctrl.clear();
    setState(() => _selectedImage = null);

    await provider.send(
      chatId: widget.chatId,
      messageText: text,
      imageFile: imageFile,
      otherUserId: widget.otherUserId,
    );

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    // listen: false because we drive UI through the cached StreamBuilder,
    // not through Provider rebuilds.
    final chatProvider =
        Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              // Re-uses the same stream — no new Firestore listener on rebuild.
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: _purple),
                  );
                }

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    final showAvatar = !isMe &&
                        (i == 0 ||
                            messages[i - 1].senderId == currentUserId);
                    return _buildMessageBubble(msg, isMe, showAvatar);
                  },
                );
              },
            ),
          ),
          if (_selectedImage != null) _buildImagePreview(),
          _buildInputBar(chatProvider),
        ],
      ),
    );
  }

  // ───────── EMPTY STATE ─────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: _purpleLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 36,
              color: _purple,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "No messages yet",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "Say hello to ${widget.otherUserName}!",
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ───────── MESSAGE BUBBLE ─────────
  Widget _buildMessageBubble(
      ChatMessage msg, bool isMe, bool showAvatar) {
    final hasImage = msg.imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildOtherUserAvatar(showAvatar),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.72,
            ),
            child: Container(
              padding: hasImage
                  ? const EdgeInsets.all(5)
                  : const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _purple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildBubbleContent(msg, isMe),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── BUBBLE CONTENT ─────────
  Widget _buildBubbleContent(ChatMessage msg, bool isMe) {
    final hasImage = msg.imageUrl.isNotEmpty;
    final hasText = msg.message.trim().isNotEmpty;

    final textStyle = TextStyle(
      color: isMe ? Colors.white : const Color(0xFF1A1A2E),
      fontSize: 14.5,
      height: 1.3,
    );

    if (!hasImage && hasText) {
      return Text(msg.message.trim(), style: textStyle);
    }

    if (hasImage && !hasText) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          msg.imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              height: 160,
              width: 200,
              color: _purpleLight,
              child: const Center(
                child: CircularProgressIndicator(
                  color: _purple,
                  strokeWidth: 2,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            height: 100,
            width: 160,
            color: _purpleLight,
            child: const Icon(Icons.broken_image, color: _purple),
          ),
        ),
      );
    }

    if (hasImage && hasText) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              msg.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(
                  height: 160,
                  width: 200,
                  color: _purpleLight,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: _purple,
                      strokeWidth: 2,
                    ),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                height: 100,
                width: 160,
                color: _purpleLight,
                child: const Icon(Icons.broken_image, color: _purple),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Text(msg.message.trim(), style: textStyle),
          ),
        ],
      );
    }

    // Fallback — empty message
    return const SizedBox.shrink();
  }

  // ───────── OTHER USER AVATAR ─────────
  Widget _buildOtherUserAvatar(bool showAvatar) {
    return Container(
      width: 32,
      margin: const EdgeInsets.only(right: 8),
      child: showAvatar
          ? CircleAvatar(
              radius: 14,
              backgroundColor: _purpleLight,
              backgroundImage: widget.otherUserProfilePic != null
                  ? NetworkImage(widget.otherUserProfilePic!)
                  : null,
              child: widget.otherUserProfilePic == null
                  ? Text(
                      widget.otherUserName[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 10,
                        color: _purple,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            )
          : const SizedBox.shrink(),
    );
  }

  // ───────── IMAGE PREVIEW ─────────
  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      color: Colors.white,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _selectedImage!,
              height: 110,
              width: 110,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            left: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 14,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ───────── INPUT BAR ─────────
  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        10,
        8,
        10,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8E8E8))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Image picker
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: _purpleLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.image_outlined,
                color: _purple,
                size: 20,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Text field
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                  fontSize: 14.5,
                  color: Color(0xFF1A1A2E),
                ),
                decoration: const InputDecoration(
                  hintText: "Message...",
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 10),
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send / mic button
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: (_hasText || _selectedImage != null)
                ? GestureDetector(
                    key: const ValueKey('send'),
                    onTap: () => _sendMessage(provider),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: _purple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  )
                : GestureDetector(
                    key: const ValueKey('mic'),
                    // TODO: Implement voice message recording
                    onTap: () {},
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        // Visually dimmed to signal "not yet active"
                        color: _purpleLight.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mic_none_rounded,
                        color: _purple.withOpacity(0.5),
                        size: 20,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ───────── APP BAR ─────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A2E)),
      titleSpacing: 0,
      title: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _purpleLight,
                backgroundImage: widget.otherUserProfilePic != null
                    ? NetworkImage(widget.otherUserProfilePic!)
                    : null,
                child: widget.otherUserProfilePic == null
                    ? Text(
                        widget.otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 1,
                right: 1,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E),
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              // TODO: Replace with real presence data from Firestore
              // e.g. StreamBuilder on users/{uid}/isOnline
              const Text(
                "Online",
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF22C55E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined),
          // TODO: Implement video call
          onPressed: () {},
          color: _purple,
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          // TODO: Implement voice call
          onPressed: () {},
          color: _purple,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(
          height: 1,
          color: Colors.grey.shade100,
        ),
      ),
    );
  }
}