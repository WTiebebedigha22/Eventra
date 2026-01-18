import 'package:flutter/material.dart';

// --- Color Palette from CreatePostScreen ---
const Color primaryColor = Color(0xFF3E5992);
const Color backgroundColor = Colors.white;
const Color white12 = Color(0xFF181818);
const Color textColor = Colors.black54;

class TagPeopleScreen extends StatelessWidget {
  const TagPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: white12,
        title: const Text('Tag People', style: TextStyle(color: textColor)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const Center(
        child: Text(
          "Search & Select Users to Tag",
          style: TextStyle(color: primaryColor, fontSize: 20),
        ),
      ),
    );
  }
}