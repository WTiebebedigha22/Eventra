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
  final _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  // ✅ FIX 1: No FocusNode — was causing the IME/keyboard crash
  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  File? _selectedImage;
  bool _hasText = false;

  static const Color _purple = Color(0xFF6C4EF2);
  static const Color _purpleLight = Color(0xFFEDE9FD);
  static const Color _bg = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(() {
      final hasText = _ctrl.text.trim().isNotEmpty;
      if (hasText != _hasText) setState(() => _hasText = hasText);
    });
  }

  @override
  void dispose() {
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
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _sendMessage(ChatProvider provider) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    await provider.send(
      chatId: widget.chatId,
      messageText: text,
      imageFile: _selectedImage,
      otherUserId: widget.otherUserId,
    );

    _ctrl.clear();
    setState(() => _selectedImage = null);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider =
        Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: chatProvider.loadChat(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
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
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    final showAvatar = !isMe &&
                        (i == messages.length - 1 ||
                            messages[i + 1].senderId ==
                                currentUserId);
                    return _buildMessage(msg, isMe, showAvatar);
                  },
                );
              },
            ),
          ),
          _buildImagePreview(),
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
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ───────── MESSAGE BUBBLE ─────────
  Widget _buildMessage(
      ChatMessage msg, bool isMe, bool showAvatar) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            if (showAvatar)
              CircleAvatar(
                radius: 14,
                backgroundColor: _purpleLight,
                backgroundImage: widget.otherUserProfilePic != null
                    ? NetworkImage(widget.otherUserProfilePic!)
                    : null,
                child: widget.otherUserProfilePic == null
                    ? Text(
                        widget.otherUserName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _purple,
                        ),
                      )
                    : null,
              )
            else
              const SizedBox(width: 28),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.68,
            ),
            child: Container(
              // ✅ FIX 2: padding based on whether it's an image message
              padding: _hasImage(msg)
                  ? const EdgeInsets.all(4)
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
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: _buildBubbleContent(msg, isMe),
            ),
          ),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // ✅ FIX 2: Central helper — check imageUrl is non-empty string
  bool _hasImage(ChatMessage msg) => msg.imageUrl.isNotEmpty;

  Widget _buildBubbleContent(ChatMessage msg, bool isMe) {
    final textStyle = TextStyle(
      color: isMe ? Colors.white : const Color(0xFF1A1A2E),
      fontSize: 14.5,
      height: 1.4,
    );

    // ✅ FIX 2: Use _hasImage() not null check — imageUrl is non-nullable
    if (_hasImage(msg)) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                height: 160,
                width: 200,
                decoration: BoxDecoration(
                  color: _purpleLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.broken_image_outlined,
                  color: _purple,
                ),
              ),
            ),
          ),
          // ✅ Caption below image if both exist
          if (msg.message.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
              child: Text(msg.message, style: textStyle),
            ),
        ],
      );
    }

    // ✅ FIX 2: Pure text message — only reached when imageUrl is empty
    return Text(
      msg.message.isNotEmpty ? msg.message : '',
      style: textStyle,
    );
  }

  // ───────── IMAGE PREVIEW ─────────
  Widget _buildImagePreview() {
    if (_selectedImage == null) return const SizedBox.shrink();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _InputIconButton(
            icon: Icons.image_outlined,
            onTap: _pickImage,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 120),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: TextField(
                controller: _ctrl,
                // ✅ FIX 1: No focusNode, no autofocus — kills the IME error
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
                onSubmitted: (_) => _sendMessage(provider),
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: _hasText || _selectedImage != null
                ? _SendButton(
                    key: const ValueKey('send'),
                    onTap: () => _sendMessage(provider),
                  )
                : _InputIconButton(
                    key: const ValueKey('mic'),
                    icon: Icons.mic_none_rounded,
                    onTap: () {},
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
          onPressed: () {},
          color: _purple,
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined),
          onPressed: () {},
          color: _purple,
        ),
        const SizedBox(width: 4),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: Colors.grey.shade100),
      ),
    );
  }
}

// ───────── REUSABLE WIDGETS ─────────

class _InputIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _InputIconButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFFEDE9FD),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.image_outlined,
          color: Color(0xFF6C4EF2),
          size: 20,
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SendButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          color: Color(0xFF6C4EF2),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.send_rounded,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}