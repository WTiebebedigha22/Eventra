import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();

  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Colors.black54;

  @override
  void initState() {
    super.initState();
    _service.init(); // 🔥 initialize FCM
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Push Notifications',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _service.getSettings(),
        builder: (context, snapshot) {
          final data = snapshot.data ?? {};

          bool pauseAll = data['pauseAll'] ?? false;
          bool reminders = data['eventReminders'] ?? true;
          bool newEvents = data['newEvents'] ?? true;
          bool messages = data['messages'] ?? true;
          bool social = data['social'] ?? true;

          return ListView(
            physics: const BouncingScrollPhysics(),
            children: [
              _buildHeader("General"),
              _buildSettingsGroup([
                _buildSwitchTile(
                  title: 'Pause All',
                  subtitle: 'Temporarily silence all alerts',
                  value: pauseAll,
                  onChanged: (val) async {
                    HapticFeedback.lightImpact();

                    await _service.updateSettings({'pauseAll': val});
                    await _service.setNotificationsEnabled(!val);
                  },
                ),
              ]),

              _buildHeader("Event Activity"),
              _buildSettingsGroup([
                _buildSwitchTile(
                  title: 'Event Reminders',
                  subtitle: '1 hour before your booked events',
                  value: reminders,
                  onChanged: pauseAll
                      ? null
                      : (val) async {
                          await _service.updateSettings({'eventReminders': val});
                        },
                  showDivider: true,
                ),
                _buildSwitchTile(
                  title: 'New Events',
                  subtitle: 'Based on your interests',
                  value: newEvents,
                  onChanged: pauseAll
                      ? null
                      : (val) async {
                          await _service.updateSettings({'newEvents': val});
                        },
                ),
              ]),

              _buildHeader("Social"),
              _buildSettingsGroup([
                _buildSwitchTile(
                  title: 'Chat Messages',
                  subtitle: 'Direct messages',
                  value: messages,
                  onChanged: pauseAll
                      ? null
                      : (val) async {
                          await _service.updateSettings({'messages': val});
                        },
                  showDivider: true,
                ),
                _buildSwitchTile(
                  title: 'Likes & Comments',
                  subtitle: 'Activity on your posts',
                  value: social,
                  onChanged: pauseAll
                      ? null
                      : (val) async {
                          await _service.updateSettings({'social': val});
                        },
                ),
              ]),

              const Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'To completely disable notifications, use device settings.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: subtleText, fontSize: 12),
                ),
              ),
            ],
          );
        },
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
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        ),
        if (showDivider) Divider(height: 1, color: Colors.grey[200]),
      ],
    );
  }
}