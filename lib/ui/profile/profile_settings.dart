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
  static const Color primaryColor = Colors.deepPurpleAccent;
  static const Color backgroundColor = Colors.white;
  static const Color surfaceColor = Color(0xFFF6F7FB);
  static const Color textColor = Color(0xFF1C1E21);
  static const Color dangerColor = Color(0xFFD93025);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {'title': 'Edit Profile', 'icon': Icons.person_outline, 'route': '/profile/edit_profile'},
        {'title': 'Security', 'icon': Icons.security_outlined, 'route': '/settings/security'},
        {'title': 'Activity', 'icon': Icons.timeline, 'route': '/settings/activity'},
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {'title': 'Notifications', 'icon': Icons.notifications_none, 'route': '/settings/notifications'},
        {'title': 'Theme', 'icon': Icons.dark_mode_outlined, 'route': '/settings/theme'},
        {'title': 'Language', 'icon': Icons.language_outlined, 'route': '/settings/language'},
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {'title': 'Help Center', 'icon': Icons.help_outline},
        {'title': 'Privacy Policy', 'icon': Icons.verified_user_outlined},
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
    final filteredGroups = settingGroups.map((group) {
      final filteredItems = (group['items'] as List).where((item) {
        return item['title']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
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
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => context.pop(),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 🔍 Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildSearchBar(),
            ),
          ),

          filteredGroups.isEmpty
              ? const SliverFillRemaining(
                  child: Center(
                    child: Text("No settings found",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildGroup(context, filteredGroups[index]),
                    childCount: filteredGroups.length,
                  ),
                ),

          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }

  // 🔍 SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search settings...",
          prefixIcon: const Icon(Icons.search, color: primaryColor),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = "");
                  },
                )
              : null,
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 📦 GROUP
  Widget _buildGroup(BuildContext context, Map<String, dynamic> group) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 8),
            child: Text(
              group['title'].toUpperCase(),
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
            ),
            child: Column(
              children: (group['items'] as List).map((item) {
                return _buildTile(context, item);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ⚙️ TILE
  Widget _buildTile(BuildContext context, Map<String, dynamic> item) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final bool isDanger = item['isDanger'] ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDanger
              ? dangerColor.withOpacity(0.1)
              : primaryColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          item['icon'],
          color: isDanger ? dangerColor : primaryColor,
          size: 20,
        ),
      ),
      title: Text(
        item['title'],
        style: TextStyle(
          color: isDanger ? dangerColor : textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 18),
      onTap: () {
        if (item['route'] != null) {
          context.push(item['route']);
        } else if (item['action'] == 'logout') {
          _confirm(
            context,
            "Logout",
            "Are you sure?",
            () async {
              await auth.logout();
              if (context.mounted) context.go('/login');
            },
          );
        } else if (item['action'] == 'delete') {
          _confirm(
            context,
            "Delete Account",
            "This cannot be undone.",
            () {},
            isDanger: true,
          );
        }
      },
    );
  }

  // ⚠️ CONFIRM DIALOG
  void _confirm(
    BuildContext context,
    String title,
    String text,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              context.pop();
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDanger ? dangerColor : primaryColor,
            ),
            child: const Text("Confirm"),
          )
        ],
      ),
    );
  }
}