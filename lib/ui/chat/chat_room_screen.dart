import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
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
  final String currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color bgSecondary = Color(0xFFF7F8FA);

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator.adaptive());
                  }

                  final messages = snapshot.data ?? [];

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final bool isMe = msg.senderId == currentUserId;
                      
                      // Grouping logic
                      final bool isSameAsPrevious = index < messages.length - 1 &&
                          messages[index + 1].senderId == msg.senderId;
                      
                      // Date divider logic (using .createdAt from your model)
                      bool showDateDivider = false;
                      if (index == messages.length - 1) {
                        showDateDivider = true;
                      } else {
                        final prevDate = messages[index + 1].createdAt;
                        if (msg.createdAt.day != prevDate.day || 
                            msg.createdAt.month != prevDate.month ||
                            msg.createdAt.year != prevDate.year) {
                          showDateDivider = true;
                        }
                      }

                      return Column(
                        children: [
                          if (showDateDivider) _buildDateDivider(msg.createdAt),
                          _buildMessageBubble(msg, isMe, isSameAsPrevious),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ),
          _buildInputBar(chatProvider),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    String label = DateFormat('MMMM d, y').format(date);
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      label = "Today";
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: primaryColor.withOpacity(0.1),
            backgroundImage: widget.otherUserProfilePic != null ? NetworkImage(widget.otherUserProfilePic!) : null,
            child: widget.otherUserProfilePic == null 
              ? Text(widget.otherUserName[0], style: const TextStyle(color: primaryColor, fontSize: 14)) 
              : null,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Row(
                children: [
                  CircleAvatar(radius: 3, backgroundColor: Colors.green),
                  SizedBox(width: 4),
                  Text("Online", style: TextStyle(color: Colors.grey, fontSize: 11)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool isGrouped) {
    return Padding(
      padding: EdgeInsets.only(top: isGrouped ? 2 : 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              decoration: BoxDecoration(
                color: isMe ? primaryColor : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMe ? 16 : (isGrouped ? 16 : 4)),
                  bottomRight: Radius.circular(isMe ? (isGrouped ? 16 : 4) : 16),
                ),
                boxShadow: [
                  if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 2))
                ],
              ),
              child: Text(
                msg.message,
                style: TextStyle(
                  color: isMe ? Colors.white : Colors.black87,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
            if (!isGrouped)
              Padding(
                padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                child: Text(
                  _formatTime(msg.createdAt), // Synchronized with your model
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(ChatProvider provider) {
    return Container(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 12, 
        bottom: MediaQuery.of(context).padding.bottom + 12
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: bgSecondary,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 4,
                minLines: 1,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final text = _ctrl.text.trim();
              if (text.isEmpty) return;
              _ctrl.clear();
              
              await provider.send(
                chatId: widget.chatId,
                messageText: text,
                otherUserId: widget.otherUserId,
              );
              _scrollToBottom();
            },
            icon: const CircleAvatar(
              radius: 20,
              backgroundColor: primaryColor,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}