import 'package:flutter/material.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  static const Color primaryPink = Color(0xFFE91E63);
  static const Color backgroundColor = Colors.black;
  static const Color appBarColor = Color(0xFF181818);
  static const Color textColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    String selectedTheme = 'Dark'; // Mock value
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        title: const Text('App Theme', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Dark', style: TextStyle(color: textColor)),
            value: 'Dark',
            groupValue: selectedTheme,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          RadioListTile<String>(
            title: const Text('Light (Not Recommended)', style: TextStyle(color: textColor)),
            value: 'Light',
            groupValue: selectedTheme,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          RadioListTile<String>(
            title: const Text('System Default', style: TextStyle(color: textColor)),
            value: 'System Default',
            groupValue: selectedTheme,
            onChanged: (val) {},
            activeColor: primaryPink,
            tileColor: appBarColor,
          ),
        ],
      ),
    );
  }
}