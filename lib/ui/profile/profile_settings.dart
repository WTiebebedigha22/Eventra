import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA); // Light grey for tiles
  static const Color textColor = Color(0xFF1C1E21);
  static const Color dangerColor = Color(0xFFD93025);

  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {'title': 'Edit Profile', 'icon': Icons.person_outline, 'route': '/profile/edit', 'isDanger': false},
        {'title': 'Security', 'icon': Icons.security_outlined, 'route': '/settings/security', 'isDanger': false},
        {'title': 'Activity', 'icon': Icons.timeline, 'route': '/settings/activity', 'isDanger': false},
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {'title': 'Notifications', 'icon': Icons.notifications_none, 'route': '/settings/notifications', 'isDanger': false},
        {'title': 'Theme', 'icon': Icons.brightness_6_outlined, 'route': '/settings/theme', 'isDanger': false},
        {'title': 'Language', 'icon': Icons.language_outlined, 'route': '/settings/language', 'isDanger': false},
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {'title': 'Help', 'icon': Icons.help_outline, 'route': '/settings/help', 'isDanger': false},
        {'title': 'Privacy Policy', 'icon': Icons.verified_user_outlined, 'route': '/settings/privacy', 'isDanger': false},
      ],
    },
    {
      'title': 'Danger Zone',
      'items': [
        {'title': 'Log Out', 'icon': Icons.logout, 'action': 'logout', 'isDanger': true},
        {'title': 'Delete Account', 'icon': Icons.delete_forever_outlined, 'action': 'delete', 'isDanger': true},
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Settings',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // --- Search Bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: EdgeInsets.zero,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // --- Settings List ---
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, groupIndex) {
                final group = settingGroups[groupIndex];
                return _buildGroup(context, group);
              },
              childCount: settingGroups.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  Widget _buildGroup(BuildContext context, Map<String, dynamic> group) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 20, top: 20, bottom: 8),
          child: Text(
            group['title'].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: (group['items'] as List).map((item) {
              final bool isLast = group['items'].last == item;
              return Column(
                children: [
                  _buildSettingTile(
                    context,
                    item['title'],
                    item['icon'],
                    route: item['route'],
                    action: item['action'],
                    isDanger: item['isDanger'],
                  ),
                  if (!isLast)
                    Divider(height: 1, indent: 55, color: Colors.grey.withOpacity(0.1)),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(BuildContext context, String title, IconData icon,
      {String? route, String? action, bool isDanger = false}) {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDanger ? dangerColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDanger ? dangerColor : primaryColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDanger ? dangerColor : textColor,
          fontWeight: isDanger ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: () {
        if (route != null) {
          context.push(route);
        } else if (action == 'logout') {
          _showConfirmDialog(context, "Logout", "Are you sure you want to sign out?", "Logout", () async {
            await auth.logout();
            if (context.mounted) context.go('/login');
          });
        } else if (action == 'delete') {
          _showConfirmDialog(context, "Delete Account", "This action is permanent and cannot be undone.", "Delete", () {
            // Implement delete logic
          }, isDestructive: true);
        }
      },
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String content, String confirmText, VoidCallback onConfirm, {bool isDestructive = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              context.pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? dangerColor : primaryColor,
              elevation: 0,
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}