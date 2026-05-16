import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../app/app_theme.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() =>
      _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState
    extends State<ProfileSettingsScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  String _searchQuery = "";

  final List<Map<String, dynamic>> settingGroups = const [
    {
      'title': 'Account',
      'items': [
        {
          'title': 'Edit Profile',
          'icon': Icons.person_outline,
          'route': '/profile/edit_profile'
        },
        {
          'title': 'Security',
          'icon': Icons.security_outlined,
          'route': '/settings/security'
        },
        {
          'title': 'Activity',
          'icon': Icons.timeline,
          'route': '/settings/activity'
        },
      ],
    },
    {
      'title': 'Content & Display',
      'items': [
        {
          'title': 'Notifications',
          'icon': Icons.notifications_none,
          'route': '/settings/notifications'
        },
        {
          'title': 'Theme',
          'icon': Icons.dark_mode_outlined,
          'route': '/settings/theme'
        },
        {
          'title': 'Language',
          'icon': Icons.language_outlined,
          'route': '/settings/language'
        },
      ],
    },
    {
      'title': 'Support & About',
      'items': [
        {
          'title': 'Help Center',
          'icon': Icons.help_outline
        },
        {
          'title': 'Privacy Policy',
          'icon': Icons.verified_user_outlined
        },
      ],
    },
    {
      'title': 'Danger Zone',
      'items': [
        {
          'title': 'Log Out',
          'icon': Icons.logout,
          'action': 'logout',
          'isDanger': true
        },
        {
          'title': 'Delete Account',
          'icon': Icons.delete_forever_outlined,
          'action': 'delete',
          'isDanger': true
        },
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
    final filteredGroups = settingGroups
        .map((group) {
          final filteredItems =
              (group['items'] as List).where((item) {
            return item['title']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase());
          }).toList();

          return {
            ...group,
            'items': filteredItems,
          };
        })
        .where(
          (group) => (group['items'] as List).isNotEmpty,
        )
        .toList();

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,

      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        centerTitle: true,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),

        title: Text(
          'Settings',
          style: AppTextStyles.headlineMedium,
        ),
      ),

      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          /// HEADER CARD
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                18,
                8,
                18,
                0,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.cardGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.borderDefault,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.accentPurple
                            .withOpacity(.12),
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.settings_rounded,
                        color: AppColors.accentPurple,
                        size: 28,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Manage Preferences',
                            style:
                                AppTextStyles.headlineMedium,
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Customize your app experience.',
                            style:
                                AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          /// SEARCH
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: _buildSearchBar(),
            ),
          ),

          filteredGroups.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Text(
                      "No settings found",
                      style:
                          AppTextStyles.bodyMedium,
                    ),
                  ),
                )
              : SliverList(
                  delegate:
                      SliverChildBuilderDelegate(
                    (context, index) => _buildGroup(
                      context,
                      filteredGroups[index],
                    ),
                    childCount:
                        filteredGroups.length,
                  ),
                ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }

  /// SEARCH BAR
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.borderDefault,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: AppTextStyles.bodyLarge,

        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },

        decoration: InputDecoration(
          hintText: "Search settings...",
          hintStyle: AppTextStyles.bodyMedium,

          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.accentPurple,
          ),

          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    _searchController.clear();

                    setState(() {
                      _searchQuery = "";
                    });
                  },
                )
              : null,

          border: InputBorder.none,
        ),
      ),
    );
  }

  /// GROUP
  Widget _buildGroup(
    BuildContext context,
    Map<String, dynamic> group,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: 20,
              bottom: 10,
            ),
            child: Text(
              group['title']
                  .toString()
                  .toUpperCase(),
              style: AppTextStyles.labelSmall,
            ),
          ),

          Container(
            margin:
                const EdgeInsets.symmetric(
              horizontal: 16,
            ),

            decoration: BoxDecoration(
              color: AppColors.bgSecondary,
              borderRadius:
                  BorderRadius.circular(22),
              border: Border.all(
                color: AppColors.borderDefault,
              ),
            ),

            child: Column(
              children:
                  (group['items'] as List)
                      .asMap()
                      .entries
                      .map((entry) {
                final index = entry.key;
                final item = entry.value;

                return Column(
                  children: [
                    _buildTile(context, item),

                    if (index !=
                        (group['items'] as List)
                                .length -
                            1)
                      const Divider(
                        height: 1,
                      ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// TILE
  Widget _buildTile(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final auth =
        Provider.of<AuthProvider>(
      context,
      listen: false,
    );

    final bool isDanger =
        item['isDanger'] ?? false;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 6,
      ),

      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDanger
              ? AppColors.error
                  .withOpacity(.12)
              : AppColors.accentPurple
                  .withOpacity(.12),
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: Icon(
          item['icon'],
          color: isDanger
              ? AppColors.error
              : AppColors.accentPurple,
          size: 22,
        ),
      ),

      title: Text(
        item['title'],
        style:
            AppTextStyles.titleMedium.copyWith(
          color: isDanger
              ? AppColors.error
              : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),

      trailing: Icon(
        Icons.chevron_right_rounded,
        color: isDanger
            ? AppColors.error
            : AppColors.textSecondary,
      ),

      onTap: () {
        if (item['route'] != null) {
          context.push(item['route']);
        } else if (item['action'] ==
            'logout') {
          _confirm(
            context,
            "Logout",
            "Are you sure you want to logout?",
            () async {
              await auth.logout();

              if (context.mounted) {
                context.go('/login');
              }
            },
          );
        } else if (item['action'] ==
            'delete') {
          _confirm(
            context,
            "Delete Account",
            "This action cannot be undone.",
            () {},
            isDanger: true,
          );
        }
      },
    );
  }

  /// CONFIRM DIALOG
  void _confirm(
    BuildContext context,
    String title,
    String text,
    VoidCallback onConfirm, {
    bool isDanger = false,
  }) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor:
              AppColors.bgSecondary,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(24),
          ),

          title: Text(
            title,
            style:
                AppTextStyles.headlineSmall,
          ),

          content: Text(
            text,
            style:
                AppTextStyles.bodyMedium,
          ),

          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                "Cancel",
                style:
                    AppTextStyles.labelLarge,
              ),
            ),

            ElevatedButton(
              onPressed: () {
                context.pop();
                onConfirm();
              },

              style:
                  ElevatedButton.styleFrom(
                backgroundColor: isDanger
                    ? AppColors.error
                    : AppColors
                        .accentPurple,
                minimumSize:
                    const Size(100, 45),
              ),

              child: const Text(
                "Confirm",
              ),
            ),
          ],
        );
      },
    );
  }
}