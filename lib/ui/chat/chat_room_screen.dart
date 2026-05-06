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

  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  late Stream<List<ChatMessage>> _messageStream;
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

    final provider = Provider.of<ChatProvider>(context, listen: false);
    _messageStream = provider.loadChat(widget.chatId);

    // ✅ Works now that markAsRead is in ChatProvider
    provider.markAsRead(widget.chatId);

    _chatSub = _messageStream.listen(
      (msgs) => debugPrint(">> Received ${msgs.length} messages"),
      onError: (e) => debugPrint(">> Stream Error: $e"),
    );
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
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  Future<void> _sendMessage() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    final imageFile = _selectedImage;
    _ctrl.clear();
    setState(() {
      _selectedImage = null;
      _hasText = false;
    });

    await Provider.of<ChatProvider>(context, listen: false).send(
      chatId: widget.chatId,
      messageText: text,
      imageFile: imageFile,
      otherUserId: widget.otherUserId,
    );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: _purple));
                }
                if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));

                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final msg = messages[i];
                    final isMe = msg.senderId == currentUserId;
                    final showAvatar = !isMe && (i == 0 || messages[i - 1].senderId == currentUserId);
                    return _buildMessageBubble(msg, isMe, showAvatar);
                  },
                );
              },
            ),
          ),
          if (_selectedImage != null) _buildImagePreview(),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(color: _purpleLight, shape: BoxShape.circle),
            child: const Icon(Icons.chat_bubble_outline_rounded, size: 36, color: _purple),
          ),
          const SizedBox(height: 16),
          const Text("No messages yet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool showAvatar) {
    final hasImage = msg.imageUrl.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildOtherUserAvatar(showAvatar),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
            child: Container(
              padding: hasImage ? const EdgeInsets.all(5) : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? _purple : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: _buildBubbleContent(msg, isMe),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubbleContent(ChatMessage msg, bool isMe) {
    final hasImage = msg.imageUrl.isNotEmpty;
    final hasText = msg.message.trim().isNotEmpty;
    final textStyle = TextStyle(color: isMe ? Colors.white : const Color(0xFF1A1A2E), fontSize: 14.5);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasImage)
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              msg.imageUrl,
              fit: BoxFit.cover,
              // ✅ FIXED: Using loadingBuilder and errorBuilder for Image.network
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 160, width: 200, color: _purpleLight,
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                );
              },
              errorBuilder: (context, error, stackTrace) => 
                const SizedBox(height: 160, width: 200, child: Icon(Icons.broken_image)),
            ),
          ),
        if (hasImage && hasText) const SizedBox(height: 6),
        if (hasText) Text(msg.message, style: textStyle),
      ],
    );
  }

  Widget _buildOtherUserAvatar(bool showAvatar) {
    return Container(
      width: 32,
      margin: const EdgeInsets.only(right: 8),
      child: showAvatar
          ? CircleAvatar(
              radius: 14,
              backgroundColor: _purpleLight,
              backgroundImage: widget.otherUserProfilePic != null ? NetworkImage(widget.otherUserProfilePic!) : null,
              child: widget.otherUserProfilePic == null
                  ? Text(widget.otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 10, color: _purple, fontWeight: FontWeight.bold))
                  : null,
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      color: Colors.white,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(_selectedImage!, height: 110, width: 110, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4, left: 4,
            child: GestureDetector(
              onTap: () => setState(() => _selectedImage = null),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 8, 10, MediaQuery.of(context).padding.bottom + 10),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE8E8E8)))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(icon: const Icon(Icons.image_outlined, color: _purple), onPressed: _pickImage),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(24)),
              child: TextField(
                controller: _ctrl,
                maxLines: null,
                decoration: const InputDecoration(hintText: "Message...", border: InputBorder.none, isDense: true),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: (_hasText || _selectedImage != null) ? _purple : _purpleLight, shape: BoxShape.circle),
              child: Icon(Icons.send_rounded, color: (_hasText || _selectedImage != null) ? Colors.white : _purple.withOpacity(0.5), size: 18),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: _purpleLight,
            backgroundImage: widget.otherUserProfilePic != null ? NetworkImage(widget.otherUserProfilePic!) : null,
            child: widget.otherUserProfilePic == null ? Text(widget.otherUserName[0]) : null,
          ),
          const SizedBox(width: 10),
          Text(widget.otherUserName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
        ],
      ),
    );
  }
}