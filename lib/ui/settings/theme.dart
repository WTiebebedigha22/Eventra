import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  late String selectedTheme;

  @override
  void initState() {
    super.initState();
    final themeProvider = context.read<ThemeProvider>();
    selectedTheme = themeProvider.currentTheme;
  }

  void _changeTheme(String value) {
    setState(() {
      selectedTheme = value;
    });

    context.read<ThemeProvider>().setTheme(value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('App Theme')),
      body: Column(
        children: [
          RadioListTile<String>(
            title: const Text('Dark'),
            value: 'Dark',
            groupValue: selectedTheme,
            onChanged: (val) => _changeTheme(val!),
            activeColor: colorScheme.primary,
          ),
          const Divider(),

          RadioListTile<String>(
            title: const Text('Light'),
            value: 'Light',
            groupValue: selectedTheme,
            onChanged: (val) => _changeTheme(val!),
            activeColor: colorScheme.primary,
          ),
          const Divider(),

          RadioListTile<String>(
            title: const Text('System Default'),
            value: 'System',
            groupValue: selectedTheme,
            onChanged: (val) => _changeTheme(val!),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }
}