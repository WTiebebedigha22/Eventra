import 'package:flutter/material.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

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
        title: const Text('Your Activity', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Recent Interactions',
              style: TextStyle(color: primaryPink, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  _buildActivityTile(
                      'Booked ticket for "Tech Summit"', '2 hours ago', Icons.confirmation_number),
                  _buildActivityTile(
                      'Liked "Art Showcase" event', 'Yesterday', Icons.favorite),
                  _buildActivityTile(
                      'Logged in on a new device', '3 days ago', Icons.login),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityTile(String title, String subtitle, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: textColor.withOpacity(0.7)),
      title: Text(title, style: const TextStyle(color: textColor)),
      subtitle: Text(subtitle, style: TextStyle(color: textColor.withOpacity(0.5))),
      tileColor: backgroundColor,
    );
  }
}