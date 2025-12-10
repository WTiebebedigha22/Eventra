import 'package:flutter/material.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    String selectedLang = 'English (US)'; // Mock value
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('Language', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: ListView(
        children: [
          RadioListTile<String>(
            title: const Text('English (US)', style: TextStyle(color: textColor)),
            value: 'English (US)',
            groupValue: selectedLang,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          RadioListTile<String>(
            title: const Text('French', style: TextStyle(color: textColor)),
            value: 'French',
            groupValue: selectedLang,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          RadioListTile<String>(
            title: const Text('Spanish', style: TextStyle(color: textColor)),
            value: 'Spanish',
            groupValue: selectedLang,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
        ],
      ),
    );
  }
}