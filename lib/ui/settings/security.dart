import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

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
        title: const Text('Security', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: textColor),
        elevation: 1,
      ),
      body: ListView(
        children: [
          // Change Password
          ListTile(
            leading: const Icon(Icons.lock_outline, color: primaryPink),
            title: const Text('Change Password', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: textColor),
            onTap: () {
              // Action: context.push('/settings/security/change-password')
            },
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
          
          // Two-Factor Authentication
          ListTile(
            leading: const Icon(Icons.verified_user_outlined, color: primaryPink),
            title: const Text('Two-Factor Authentication', style: TextStyle(color: textColor)),
            trailing: Switch(
              value: true, // Mock value
              onChanged: (val) {
                // Handle switch toggle
              },
              activeColor: primaryPink,
            ),
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),

          // Logged In Devices
          ListTile(
            leading: const Icon(Icons.devices_other, color: primaryPink),
            title: const Text('Logged In Devices', style: TextStyle(color: textColor)),
            trailing: const Icon(Icons.keyboard_arrow_right, color: textColor),
            onTap: () {
              // Action: context.push('/settings/security/devices')
            },
            tileColor: appBarColor,
          ),
          const Divider(color: backgroundColor, height: 1, thickness: 1),
        ],
      ),
    );
  }
}