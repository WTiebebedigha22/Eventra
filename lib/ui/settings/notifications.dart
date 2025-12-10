import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Notifications', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: ListView(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Manage your alerts',
              style: TextStyle(color: primaryPink.withOpacity(0.8), fontSize: 14),
            ),
          ),
          
          // Pause All Notifications
          ListTile(
            title: const Text('Pause All Notifications', style: TextStyle(color: textColor)),
            trailing: Switch(
              value: false, 
              onChanged: (val) {},
              activeColor: primaryPink,
            ),
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          
          // Event Reminders
          ListTile(
            title: const Text('Event Reminders', style: TextStyle(color: textColor)),
            subtitle: Text('Get notified 1 hour before an event starts.', style: TextStyle(color: textColor.withOpacity(0.5))),
            trailing: Switch(
              value: true, 
              onChanged: (val) {},
              activeColor: primaryPink,
            ),
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),

          // Chat Messages
          ListTile(
            title: const Text('Chat Messages', style: TextStyle(color: textColor)),
            trailing: Switch(
              value: true, 
              onChanged: (val) {},
              activeColor: primaryPink,
            ),
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
        ],
      ),
    );
  }
}