import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  // Brand Colors
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color bgSecondary = Color(0xFFF7F8FA);
  static const Color accentColor = Color(0xFF6C83B4);

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _navigateToProfile() {
    // Replace with your actual Profile Screen route
    debugPrint("Navigating to profile of ${widget.otherUserId}");
    // Navigator.pushNamed(context, '/profile', arguments: widget.otherUserId);
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Container(
        decoration: const BoxDecoration(color: bgSecondary),
        child: Column(
          children: [
            Expanded(
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
                    reverse: true, // Standard chat behavior
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      // Check if the previous message was from the same sender for UI grouping
                      final bool isSameAsPrevious = index < messages.length - 1 && 
                                                    messages[index + 1].senderId == msg.senderId;
                      
                      return _buildMessageBubble(msg, isSameAsPrevious);
                    },
                  );
                },
              ),
            ),
            _buildInputBar(chatProvider),
          ],
        ),
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
      title: InkWell(
        onTap: _navigateToProfile,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: primaryColor.withOpacity(0.1),
              backgroundImage: widget.otherUserProfilePic != null 
                  ? NetworkImage(widget.otherUserProfilePic!) 
                  : null,
              child: widget.otherUserProfilePic == null 
                  ? Text(widget.otherUserName[0], style: const TextStyle(fontSize: 14, color: primaryColor)) 
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
                const Text(
                  "Online", // You can sync this with Firestore status later
                  style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.w400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isGrouped) {
    final isMe = msg.senderId == currentUserId;
    
    return Padding(
      padding: EdgeInsets.only(top: isGrouped ? 2 : 12),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? primaryColor : Colors.white,
            boxShadow: [
              if (!isMe) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
            ],
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : (isGrouped ? 20 : 4)),
              bottomRight: Radius.circular(isMe ? (isGrouped ? 20 : 4) : 20),
            ),
          ),
          child: Text(
            msg.message,
            style: TextStyle(
              color: isMe ? Colors.white : Colors.black87,
              fontSize: 15,
              height: 1.3,
            ),
          ),
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
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: bgSecondary,
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _ctrl,
                maxLines: 4,
                minLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 15),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () async {
              final text = _ctrl.text.trim();
              if (text.isEmpty) return;
              _ctrl.clear();
              await provider.send(
                chatId: widget.chatId,
                messageText: text,
                otherUserId: widget.otherUserId,
              );
            },
            child: const CircleAvatar(
              radius: 22,
              backgroundColor: primaryColor,
              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}