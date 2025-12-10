import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  // Define your color scheme (consistent with other screens)
  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color navBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  // Mock data for chat list and 'stories'
  final List<Map<String, String>> mockChats = const [
    {'name': 'Organizer A', 'lastMessage': 'See you at the event!', 'chatId': 'organizerA'},
    {'name': 'Alex Johnson', 'lastMessage': 'Got the tickets, thanks!', 'chatId': 'alexJ'},
    {'name': 'Dev Community', 'lastMessage': 'Flutter Meetup details confirmed.', 'chatId': 'devComm'},
    {'name': 'Sarah Smith', 'lastMessage': 'The concert was awesome!', 'chatId': 'sarahS'},
  ];

  final List<String> mockStories = const [
    'Your Story', 'Friend 1', 'Friend 2', 'Organizer C', 'Event News', 'Lisa M'
  ];

  // --- Widget for a single 'Story' item (Circular Profile) ---
  Widget _buildStoryItem(BuildContext context, String name, {bool isNew = true}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Instagram Story Ring Effect: Gradient Border
              border: isNew
                  ? Border.all(
                      color: primaryPink,
                      width: 2.5,
                    )
                  : null,
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: navBarColor, // Placeholder for profile image
              child: Text(
                name[0], // First letter of name
                style: const TextStyle(color: textColor),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            name.split(' ')[0], // Display only first name
            style: const TextStyle(color: textColor, fontSize: 12),
          ),
        ],
      ),
    );
  }
  // -------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        title: const Text(
          'Chats',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          // New Message/Add Icon (Instagram style)
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: textColor, size: 28),
            onPressed: () {
              // Action for starting a new chat
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Stories Section (Horizontal List) ---
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              itemCount: mockStories.length,
              itemBuilder: (context, index) {
                return _buildStoryItem(context, mockStories[index], isNew: index != 0);
              },
            ),
          ),
          
          const Divider(color: navBarColor, height: 1), // Subtle divider

          // --- Chat List Section ---
          Expanded(
            child: ListView.builder(
              itemCount: mockChats.length,
              itemBuilder: (context, index) {
                final chat = mockChats[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  
                  // Circular Profile Picture
                  leading: CircleAvatar(
                    radius: 28,
                    backgroundColor: primaryPink.withOpacity(0.3),
                    child: Text(
                      chat['name']![0],
                      style: const TextStyle(color: primaryPink, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // User Name
                  title: Text(
                    chat['name']!,
                    style: const TextStyle(
                        color: textColor, fontWeight: FontWeight.w600),
                  ),

                  // Last Message Snippet
                  subtitle: Text(
                    chat['lastMessage']!,
                    style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Action Arrow/Icon
                  trailing: Icon(Icons.keyboard_arrow_right, color: textColor.withOpacity(0.5)),

                  // 💡 Navigation to ChatRoomScreen
                  onTap: () => context.go('/home/chat/${chat['chatId']}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}