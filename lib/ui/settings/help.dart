import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

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
        title: const Text('Help Center', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.contact_support_outlined, color: primaryPink),
            title: const Text('Contact Us', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: textColor),
            onTap: () {},
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          ListTile(
            leading: const Icon(Icons.question_answer_outlined, color: primaryPink),
            title: const Text('FAQ', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: textColor),
            onTap: () {},
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined, color: primaryPink),
            title: const Text('Report a Problem', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: textColor),
            onTap: () {},
            tileColor: appBarColor,
          ),
        ],
      ),
    );
  }
}