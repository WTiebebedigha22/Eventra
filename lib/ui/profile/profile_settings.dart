import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  // --- Theme Colors ---
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF8F9FA); 
  static const Color textColor = Color(0xFF1C1E21);
  static const Color dangerColor = Color(0xFFD93025);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {'title': 'Edit Profile', 'icon': Icons.person_outline, 'route': '/profile/edit_profile', 'isDanger': false},
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filter logic for the search bar
    final filteredGroups = settingGroups.map((group) {
      final filteredItems = (group['items'] as List).where((item) {
        return item['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      return {...group, 'items': filteredItems};
    }).where((group) => (group['items'] as List).isNotEmpty).toList();

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
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- Search Bar ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search settings...',
                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: const Icon(Icons.search, size: 20, color: primaryColor),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = "");
                          }) 
                      : null,
                  filled: true,
                  fillColor: surfaceColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ),

          // --- Settings List ---
          filteredGroups.isEmpty 
          ? const SliverFillRemaining(
              child: Center(child: Text("No settings found", style: TextStyle(color: Colors.grey))),
            )
          : SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGroup(context, filteredGroups[index]),
                childCount: filteredGroups.length,
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
          padding: const EdgeInsets.only(left: 20, top: 24, bottom: 8),
          child: Text(
            group['title'].toString().toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withOpacity(0.03)),
          ),
          child: Column(
            children: (group['items'] as List).asMap().entries.map((entry) {
              final int idx = entry.key;
              final item = entry.value;
              final bool isLast = idx == (group['items'] as List).length - 1;

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
                    Divider(height: 1, indent: 55, color: Colors.grey.withAlpha(20)),
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
          fontSize: 15,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.black26),
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
            // Add Delete logic here
          }, isDestructive: true);
        }
      },
    );
  }

  void _showConfirmDialog(BuildContext context, String title, String content, String confirmText, VoidCallback onConfirm, {bool isDestructive = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content, style: const TextStyle(color: Colors.black54)),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        actions: [
          TextButton(onPressed: () => context.pop(), child: const Text("Cancel", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              context.pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive ? dangerColor : primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            child: Text(confirmText, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}