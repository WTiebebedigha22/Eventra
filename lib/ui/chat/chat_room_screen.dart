import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/chat_provider.dart';
import '../../services/chat_service.dart';

class ChatRoomScreen extends StatefulWidget {
  final String otherUid;
  final String otherName;
  final String? otherAvatar;

  const ChatRoomScreen({
    super.key,
    required this.otherUid,
    required this.otherName,
    this.otherAvatar,
  });

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _typingTimer;
  bool _isTyping = false;
  bool _isLoading = true;
  String? _error;
  FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeChat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _initializeChat() async {
    try {
      final provider = context.read<ChatProvider>();
      await provider.initChat(widget.otherUid, widget.otherName);
      _markMessagesAsRead();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load chat: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _markMessagesAsRead() {
    final chatId = context.read<ChatService>().chatId(widget.otherUid);
    context.read<ChatProvider>().markAsRead(chatId);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _focusNode.dispose();
    // Clear typing on exit
    context.read<ChatProvider>().setTyping(widget.otherUid, false);
    super.dispose();
  }

  void _onTypingChanged(String value) {
    final provider = context.read<ChatProvider>();
    if (!_isTyping && value.isNotEmpty) {
      _isTyping = true;
      provider.setTyping(widget.otherUid, true);
    }
    
    _typingTimer?.cancel();
    if (value.isNotEmpty) {
      _typingTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _isTyping) {
          _isTyping = false;
          provider.setTyping(widget.otherUid, false);
        }
      });
    } else if (_isTyping) {
      _isTyping = false;
      provider.setTyping(widget.otherUid, false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    _controller.clear();
    if (_isTyping) {
      _isTyping = false;
      context.read<ChatProvider>().setTyping(widget.otherUid, false);
      _typingTimer?.cancel();
    }
    
    final success = await context.read<ChatProvider>().sendMessage(widget.otherUid, text);
    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Please try again.')),
        );
      }
    }
  }

  Future<void> _sendMediaMessage(String mediaUrl, String mediaType) async {
    final success = await context.read<ChatProvider>().sendMediaMessage(
      widget.otherUid,
      mediaUrl,
      mediaType,
    );
    
    if (success) {
      _scrollToBottom();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send media. Please try again.')),
        );
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.image, color: Colors.blue),
              title: const Text('Send Image'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement image picker
                _sendMediaMessage('sample_image_url', 'image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.red),
              title: const Text('Send Voice Message'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement audio recorder
                _sendMediaMessage('sample_audio_url', 'audio');
              },
            ),
            ListTile(
              leading: const Icon(Icons.videocam, color: Colors.purple),
              title: const Text('Send Video'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement video picker
                _sendMediaMessage('sample_video_url', 'video');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMessageOptions(MessageModel message) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.content_copy),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Message'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteMessage(message);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(MessageModel message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement message deletion
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message deleted')),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;
    if (myUid == null) {
      return const Scaffold(body: Center(child: Text('Please login to continue')));
    }
    
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(provider),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorWidget()
              : Column(
                  children: [
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: provider.getMessages(widget.otherUid),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                                  const SizedBox(height: 16),
                                  Text('Error: ${snapshot.error}'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => setState(() {}),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            );
                          }
                          
                          final docs = snapshot.data?.docs ?? [];
                          if (docs.isEmpty) {
                            return _buildEmptyState();
                          }
                          
                          WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                          
                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final msg = MessageModel.fromDoc(docs[index]);
                              final isMe = msg.senderId == myUid;
                              final isLast = index == docs.length - 1;
                              final showDate = index == 0 || 
                                  !_isSameDay(msg.timestamp, MessageModel.fromDoc(docs[index - 1]).timestamp);
                              
                              return Column(
                                children: [
                                  if (showDate) _buildDateDivider(msg.timestamp),
                                  _MessageBubble(
                                    message: msg,
                                    isMe: isMe,
                                    isLast: isLast,
                                    onLongPress: () => _showMessageOptions(msg),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      ),
                    ),
                    _InputBar(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: _onTypingChanged,
                      onSend: _sendMessage,
                      onAttach: _showAttachmentOptions,
                      sending: provider.sending,
                    ),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatProvider provider) {
    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.otherAvatar != null && widget.otherAvatar!.isNotEmpty
                ? NetworkImage(widget.otherAvatar!)
                : null,
            child: widget.otherAvatar == null || widget.otherAvatar!.isEmpty
                ? Text(widget.otherName[0].toUpperCase(), style: const TextStyle(fontSize: 18))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherName,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    StreamBuilder<bool>(
                      stream: provider.isOtherTyping(widget.otherUid),
                      builder: (context, snap) {
                        final typing = snap.data ?? false;
                        if (typing) {
                          return const Text(
                            'typing...',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    StreamBuilder<bool>(
                      stream: provider.isUserOnline(widget.otherUid),
                      builder: (context, snap) {
                        final isOnline = snap.data ?? false;
                        if (!isOnline) return const SizedBox.shrink();
                        return Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Online',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showChatOptions(),
        ),
      ],
    );
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.red),
              title: const Text('Block User'),
              onTap: () {
                Navigator.pop(context);
                _confirmBlockUser();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Conversation'),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteConversation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBlockUser() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: Text('Are you sure you want to block ${widget.otherName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await context.read<ChatProvider>().blockUser(widget.otherUid);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${widget.otherName} has been blocked')),
                );
              }
            },
            child: const Text('Block', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: Text('Are you sure you want to delete your conversation with ${widget.otherName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final chatId = context.read<ChatService>().chatId(widget.otherUid);
              Navigator.pop(context);
              final success = await context.read<ChatProvider>().deleteConversation(chatId);
              if (success && mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Conversation deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No messages yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Say hello to ${widget.otherName}! 👋',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'An error occurred'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _isLoading = true;
                _error = null;
                _initializeChat();
              });
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);
    
    String dateText;
    if (messageDate == today) {
      dateText = 'Today';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Yesterday';
    } else {
      dateText = DateFormat('MMMM d, yyyy').format(date);
    }
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            dateText,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isLast;
  final VoidCallback? onLongPress;

  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.isLast,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('h:mm a').format(message.timestamp);
    
    return GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.messageType != null && message.messageType != 'text')
                    _buildMediaIndicator(),
                  Text(
                    message.text,
                    style: TextStyle(
                      color: isMe
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
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
                  time,
                  style: TextStyle(
                    fontSize: 10,
                    color: isMe
                        ? Theme.of(context).colorScheme.onPrimary.withOpacity(0.7)
                        : Colors.grey[500],
                  ),
                ),
                if (isMe && isLast) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 12,
                    color: message.read
                        ? Colors.lightBlueAccent
                        : Colors.grey[400],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaIndicator() {
    IconData icon;
    String label;
    
    switch (message.messageType) {
      case 'image':
        icon = Icons.image;
        label = 'Image';
        break;
      case 'audio':
        icon = Icons.mic;
        label = 'Voice Message';
        break;
      case 'video':
        icon = Icons.videocam;
        label = 'Video';
        break;
      default:
        return const SizedBox.shrink();
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isMe ? Colors.white : Colors.grey),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isMe ? Colors.white70 : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSend;
  final VoidCallback onAttach;
  final bool sending;

  const _InputBar({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSend,
    required this.onAttach,
    required this.sending,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: onAttach,
              icon: const Icon(Icons.attach_file),
              color: Colors.grey[600],
            ),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: (_) => onSend(),
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: InputDecoration(
                  hintText: 'Message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            sending
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: controller.text.trim().isEmpty ? null : onSend,
                      icon: const Icon(Icons.send_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: controller.text.trim().isEmpty
                            ? Colors.grey[300]
                            : Theme.of(context).colorScheme.primary,
                        foregroundColor: controller.text.trim().isEmpty
                            ? Colors.grey[500]
                            : Theme.of(context).colorScheme.onPrimary,
                        shape: const CircleBorder(),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}