// widgets/chat_message_bubble.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isMe;
  final DateTime timestamp;
  final bool isRead;
  final String? messageType;
  final VoidCallback? onTap;

  const ChatMessageBubble({
    Key? key,
    required this.message,
    required this.isMe,
    required this.timestamp,
    this.isRead = false,
    this.messageType,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50 : 10,
          right: isMe ? 10 : 50,
          top: 5,
          bottom: 5,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMe ? Colors.deepPurpleAccent : Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (messageType != null && messageType != 'text')
                    _buildMediaPreview(),
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  DateFormat('HH:mm').format(timestamp),
                  style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                ),
                if (isMe && isRead)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.done_all, size: 12, color: Colors.green),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    switch (messageType) {
      case 'image':
        return const Icon(Icons.image, size: 20);
      case 'audio':
        return const Icon(Icons.mic, size: 20);
      case 'video':
        return const Icon(Icons.videocam, size: 20);
      default:
        return const SizedBox.shrink();
    }
  }
}