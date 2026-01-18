import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mock state for toggles
  bool _pauseAll = false;
  bool _reminders = true;
  bool _messages = true;
  bool _social = true;

  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Push Notifications',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          _buildHeader("General"),
          _buildSettingsGroup([
            _buildSwitchTile(
              title: 'Pause All',
              subtitle: 'Temporarily silence all alerts',
              value: _pauseAll,
              onChanged: (val) => setState(() => _pauseAll = val),
            ),
          ]),

          _buildHeader("Event Activity"),
          _buildSettingsGroup([
            _buildSwitchTile(
              title: 'Event Reminders',
              subtitle: '1 hour before your booked events',
              value: _reminders,
              onChanged: _pauseAll ? null : (val) => setState(() => _reminders = val),
              showDivider: true,
            ),
            _buildSwitchTile(
              title: 'New Events',
              subtitle: 'Based on your favorite locations',
              value: _social,
              onChanged: _pauseAll ? null : (val) => setState(() => _social = val),
            ),
          ]),

          _buildHeader("Social"),
          _buildSettingsGroup([
            _buildSwitchTile(
              title: 'Chat Messages',
              subtitle: 'Direct messages and group chats',
              value: _messages,
              onChanged: _pauseAll ? null : (val) => setState(() => _messages = val),
              showDivider: true,
            ),
            _buildSwitchTile(
              title: 'Likes & Comments',
              subtitle: 'Activity on your shared posts',
              value: true,
              onChanged: _pauseAll ? null : (val) {},
            ),
          ]),
          
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'To completely turn off notifications, visit your device System Settings.',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtleText, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: subtleText,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
    bool showDivider = false,
  }) {
    return Column(
      children: [
        SwitchListTile.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          title: Text(
            title,
            style: TextStyle(
              color: onChanged == null ? subtleText : textColor,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: subtleText),
          ),
        ),
        if (showDivider)
          Divider(indent: 16, endIndent: 16, height: 1, color: Colors.grey[100]),
      ],
    );
  }
} 