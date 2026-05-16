import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/theme_provider.dart';
import '../../app/app_theme.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late String selectedTheme;

  final List<_ThemeOption> themeOptions = const [
    _ThemeOption(
      title: 'Dark Mode',
      subtitle: 'Elegant low-light experience',
      value: 'Dark',
      icon: Icons.dark_mode_rounded,
      gradient: AppColors.purpleGradient,
    ),
    _ThemeOption(
      title: 'Light Mode',
      subtitle: 'Bright and minimal appearance',
      value: 'Light',
      icon: Icons.light_mode_rounded,
      gradient: AppColors.orangeGradient,
    ),
    _ThemeOption(
      title: 'System Default',
      subtitle: 'Automatically match device theme',
      value: 'System',
      icon: Icons.phone_android_rounded,
      gradient: AppColors.cardGradient,
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedTheme = context.read<ThemeProvider>().currentTheme;
  }

  void _changeTheme(String value) {
    setState(() {
      selectedTheme = value;
    });

    context.read<ThemeProvider>().setTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Appearance'),
      ),

      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Container(
              width: double.infinity,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withOpacity(.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.palette_rounded,
                      color: AppColors.accentPurple,
                      size: 30,
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Customize Your Experience',
                    style: AppTextStyles.headlineLarge,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Select the theme that best matches your style and comfort.',
                    style: AppTextStyles.bodyMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Theme Options',
              style: AppTextStyles.headlineMedium,
            ),

            const SizedBox(height: 16),

            Expanded(
              child: ListView.separated(
                itemCount: themeOptions.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final option = themeOptions[index];
                  final isSelected = selectedTheme == option.value;

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isSelected
                            ? option.gradient
                            : [
                                AppColors.bgCard,
                                AppColors.bgCard,
                              ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: isSelected
                            ? Colors.transparent
                            : AppColors.borderDefault,
                        width: 1.2,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: option.gradient.first.withOpacity(.25),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ]
                          : [],
                    ),
                    child: RadioListTile<String>(
                      value: option.value,
                      groupValue: selectedTheme,
                      onChanged: (value) => _changeTheme(value!),
                      activeColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),

                      /// ICON
                      secondary: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Colors.white.withOpacity(.12)
                              : AppColors.bgElevated,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          option.icon,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                        ),
                      ),

                      /// TITLE
                      title: Text(
                        option.title,
                        style: AppTextStyles.headlineSmall.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),

                      /// SUBTITLE
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          option.subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            /// FOOTER INFO
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgSecondary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.borderDefault,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.accentOrange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your selected theme will be applied across the entire app.',
                      style: AppTextStyles.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption {
  final String title;
  final String subtitle;
  final String value;
  final IconData icon;
  final List<Color> gradient;

  const _ThemeOption({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.gradient,
  });
}