import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart'; // Assume this file exists

class ChatRoomScreen extends StatefulWidget {
  final String chatId;
  const ChatRoomScreen({super.key, required this.chatId});
  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _ctrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Define your color scheme (consistent with other screens)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818); // Darker shade for contrast
  static const Color textColor = Colors.white;

  // Mock messages for demonstration
  final List<Map<String, String>> mockMessages = [
    {'text': 'Hello, is this event still on?', 'sender': 'me'},
    {'text': 'Yes, the tickets are available. How many are you looking for?', 'sender': 'other'},
    {'text': 'Two tickets please. Where can we meet to pay?', 'sender': 'me'},
    {'text': 'I can send you the payment details now, or we can use the app\'s secure payment link.', 'sender': 'other'},
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // --- Widget for a single chat bubble ---
  Widget _buildMessageBubble(String text, String sender) {
    final isMe = sender == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        decoration: BoxDecoration(
          // Distinct colors for sender and receiver
          color: isMe ? primaryPink : appBarColor, 
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: isMe ? const Radius.circular(16) : const Radius.circular(4),
            bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 3,
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black : textColor, // Black text on pink bubble
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 💡 Note: If you want real-time updates, the Consumer/Provider.of must listen to the stream.
    // final chat = Provider.of<ChatProvider>(context, listen: true); 

    // Using listen: false for the action call only
    final _ = Provider.of<ChatProvider>(context, listen: false); 
    
    _scrollToBottom(); 

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 1,
        title: Text(
          'Chat with ${widget.chatId}',
          style: const TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: primaryPink),
            onPressed: () {
              // Action: View event or contact profile
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 8, bottom: 8),
              itemCount: mockMessages.length,
              itemBuilder: (context, index) {
                final message = mockMessages[index];
                return _buildMessageBubble(message['text']!, message['sender']!);
              },
            ),
          ),
          
          // --- Input Bar ---
          Container(
            padding: const EdgeInsets.all(8.0),
            color: appBarColor, 
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt_outlined, color: primaryPink),
                  onPressed: () {
                    // Action: Send photo
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    minLines: 1,
                    maxLines: 5,
                    keyboardType: TextInputType.multiline,
                    style: const TextStyle(color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      hintStyle: TextStyle(color: textColor.withOpacity(0.6)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      filled: true,
                      fillColor: backgroundColor, 
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                
                // Send Button
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: FloatingActionButton(
                    heroTag: 'sendBtn', 
                    mini: true,
                    backgroundColor: primaryPink,
                    onPressed: () async {
                      if (_ctrl.text.trim().isEmpty) return;
                      
                      // In a real app, call the provider:
                      // await chat.send(widget.chatId, _ctrl.text.trim(), 'me');
                      
                      // For mock data:
                      setState(() {
                        mockMessages.add({'text': _ctrl.text.trim(), 'sender': 'me'});
                      });

                      _ctrl.clear();
                      _scrollToBottom();
                    },
                    child: const Icon(Icons.send, color: Colors.black),
                  ),
                ),
              ],
            ),
          )
        ]),
    );
  }
}