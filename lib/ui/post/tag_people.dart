import 'package:flutter/material.dart';

// --- Color Palette from CreatePostScreen ---
const Color primaryPink = Color(0xFFE91E63);
const Color backgroundColor = Colors.black;
const Color appBarColor = Color(0xFF181818);
const Color textColor = Colors.white;

class TagPeopleScreen extends StatelessWidget {
  const TagPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Tag People', style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          "Search & Select Users to Tag",
          style: TextStyle(color: primaryPink, fontSize: 20),
        ),
      ),
    );
  }
}