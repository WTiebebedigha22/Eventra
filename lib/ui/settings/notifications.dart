import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import '../../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  final NotificationService _service = NotificationService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF6C63FF);
  static const Color backgroundColor = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color subtleText = Color(0xFF7A7E8B);
  static const Color dividerColor = Color(0xFFEEF2F6);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
    
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    setState(() => _isLoading = true);
    await _service.init();
    setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => _showResetDialog(),
            child: const Text(
              'Reset',
              style: TextStyle(color: primaryColor),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : FadeTransition(
              opacity: _fadeAnimation,
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: _service.getSettings(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => _initializeNotifications(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  final data = snapshot.data ?? {};
                  bool pauseAll = data['pauseAll'] ?? false;
                  bool reminders = data['eventReminders'] ?? true;
                  bool newEvents = data['newEvents'] ?? true;
                  bool messages = data['messages'] ?? true;
                  bool social = data['social'] ?? true;
                  bool marketing = data['marketing'] ?? false;
                  bool updates = data['appUpdates'] ?? true;

                  return ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      const SizedBox(height: 8),
                      _buildHeader("General"),
                      _buildSettingsGroup([
                        _buildSwitchTile(
                          title: 'Pause All',
                          subtitle: 'Temporarily silence all notifications',
                          value: pauseAll,
                          onChanged: (val) async {
                            HapticFeedback.lightImpact();
                            await _service.updateSettings({'pauseAll': val});
                            await _service.setNotificationsEnabled(!val);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(val ? 'All notifications paused' : 'Notifications resumed'),
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          },
                          showDivider: false,
                        ),
                      ]),

                      _buildHeader("Event Activity"),
                      _buildSettingsGroup([
                        _buildSwitchTile(
                          title: 'Event Reminders',
                          subtitle: 'Get reminders before your booked events',
                          value: reminders && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'eventReminders': val});
                                },
                          showDivider: true,
                        ),
                        _buildSwitchTile(
                          title: 'New Events',
                          subtitle: 'Discover events based on your interests',
                          value: newEvents && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'newEvents': val});
                                },
                          showDivider: false,
                        ),
                      ]),

                      _buildHeader("Social"),
                      _buildSettingsGroup([
                        _buildSwitchTile(
                          title: 'Chat Messages',
                          subtitle: 'New message notifications',
                          value: messages && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'messages': val});
                                },
                          showDivider: true,
                        ),
                        _buildSwitchTile(
                          title: 'Likes & Comments',
                          subtitle: 'Activity on your posts and events',
                          value: social && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'social': val});
                                },
                          showDivider: false,
                        ),
                      ]),

                      _buildHeader("Updates"),
                      _buildSettingsGroup([
                        _buildSwitchTile(
                          title: 'App Updates',
                          subtitle: 'New features and improvements',
                          value: updates && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'appUpdates': val});
                                },
                          showDivider: true,
                        ),
                        _buildSwitchTile(
                          title: 'Marketing',
                          subtitle: 'Special offers and promotions',
                          value: marketing && !pauseAll,
                          onChanged: pauseAll
                              ? null
                              : (val) async {
                                  HapticFeedback.lightImpact();
                                  await _service.updateSettings({'marketing': val});
                                },
                          showDivider: false,
                        ),
                      ]),

                      _buildScheduleSection(),
                      _buildTestNotificationButton(),
                      _buildDeviceSettingsNote(),
                      const SizedBox(height: 30),
                    ],
                  );
                },
              ),
            ),
    );
  }

  Widget _buildScheduleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader("Quiet Hours"),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              _buildTimeTile(
                title: 'Start Time',
                subtitle: 'When quiet hours begin',
                onTap: () => _selectTime('start'),
              ),
              const Divider(height: 1, indent: 56, color: dividerColor),
              _buildTimeTile(
                title: 'End Time',
                subtitle: 'When quiet hours end',
                onTap: () => _selectTime('end'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeTile({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.bedtime, color: primaryColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _selectTime(String type) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: primaryColor),
        ),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      final formattedTime = time.format(context);
      await _service.updateSettings({'quiet${type == 'start' ? 'Start' : 'End'}': formattedTime});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiet hours ${type == 'start' ? 'start' : 'end'} time set to $formattedTime'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  Widget _buildTestNotificationButton() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _sendTestNotification(),
        icon: const Icon(Icons.notifications_active, size: 20),
        label: const Text('Send Test Notification'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    await _service.sendTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent! Check your device.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildDeviceSettingsNote() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text(
            'To completely disable notifications, use your device settings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: subtleText, fontSize: 12),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: () => _openDeviceSettings(),
            icon: const Icon(Icons.settings, size: 16),
            label: const Text('Open Device Settings'),
            style: TextButton.styleFrom(
              foregroundColor: primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDeviceSettings() async {
    // Open app settings on device
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please go to device settings to manage app notifications'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Notification Settings'),
        content: const Text('This will reset all notification preferences to default. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _service.resetSettings();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Settings reset to default'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
            ),
            child: const Text('Reset'),
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
          fontSize: 12,
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
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
        SwitchListTile(
          value: value,
          onChanged: onChanged,
          activeColor: primaryColor,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: subtleText)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        if (showDivider) Divider(height: 1, indent: 56, color: dividerColor),
      ],
    );
  }
}