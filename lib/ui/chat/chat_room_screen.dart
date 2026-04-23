import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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

  final String currentUserId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color bgSecondary = Color(0xFFF7F8FA);

  File? _selectedImage;

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
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  String _formatTime(DateTime date) =>
      DateFormat('h:mm a').format(date);

  @override
  Widget build(BuildContext context) {
    final chatProvider =
        Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: bgSecondary,
              child: StreamBuilder<List<ChatMessage>>(
                stream: chatProvider.loadChat(widget.chatId),
                builder: (context, snapshot) {
                  final messages = snapshot.data ?? [];

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text("No messages yet"),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, i) {
                      final msg = messages[i];
                      final isMe = msg.senderId == currentUserId;

                      return _buildMessage(msg, isMe);
                    },
                  );
                },
              ),
            ),
          ),

          // Preview selected image
          if (_selectedImage != null)
            Container(
              padding: const EdgeInsets.all(8),
              child: Stack(
                children: [
                  Image.file(_selectedImage!, height: 120),
                  Positioned(
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => _selectedImage = null),
                    ),
                  )
                ],
              ),
            ),

          _buildInputBar(chatProvider),
        ],
      ),
    );
  }

  // ───────── MESSAGE UI ─────────
  Widget _buildMessage(ChatMessage msg, bool isMe) {
    return Align(
      alignment:
          isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isMe ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: msg.imageUrl != null && msg.imageUrl!.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.network(msg.imageUrl!),
                  if (msg.message.isNotEmpty)
                    Text(
                      msg.message,
                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                ],
              )
            : Text(
                msg.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black,
                ),
              ),
      ),
    );
  }

  // ───────── INPUT BAR ─────────
  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border:
            Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.image, color: primaryColor),
            onPressed: _pickImage,
          ),

          Expanded(
            child: TextField(
              controller: _ctrl,
              decoration: const InputDecoration(
                hintText: "Message...",
                border: InputBorder.none,
              ),
            ),
          ),

          IconButton(
            icon: const Icon(Icons.send, color: primaryColor),
            onPressed: () async {
              final text = _ctrl.text.trim();

              if (text.isEmpty && _selectedImage == null) return;

              await provider.send(
                chatId: widget.chatId,
                messageText: text,
                imageFile: _selectedImage, // 🔥 NEW
                otherUserId: widget.otherUserId,
              );

              _ctrl.clear();
              setState(() => _selectedImage = null);

              _scrollToBottom();
            },
          )
        ],
      ),
    );
  }

  // ───────── APP BAR ─────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      iconTheme:
          const IconThemeData(color: Colors.deepPurpleAccent),
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage:
                widget.otherUserProfilePic != null
                    ? NetworkImage(widget.otherUserProfilePic!)
                    : null,
            child: widget.otherUserProfilePic == null
                ? Text(widget.otherUserName[0])
                : null,
          ),
          const SizedBox(width: 10),
          Text(widget.otherUserName),
        ],
      ),
    );
  }
}