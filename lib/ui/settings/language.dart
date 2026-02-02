import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  // Theme constants matching your design system
  static const Color primaryColor = Color(0xFF3E5992);
  static const Color scaffoldBg = Color(0xFFF8F9FA);
  static const Color textColor = Color(0xFF1A1A1A);
  static const Color subTextColor = Colors.black54;

  // State variable
  String _selectedLang = 'English (US)';

  // List of languages (Could be fetched from a translation service later)
  final List<Map<String, String>> _languages = [
    {'name': 'English (US)', 'native': 'English'},
    {'name': 'French', 'native': 'Français'},
    {'name': 'Spanish', 'native': 'Español'},
    {'name': 'German', 'native': 'Deutsch'},
    {'name': 'Chinese', 'native': '中文'},
    {'name': 'Arabic', 'native': 'العربية'},
  ];

  void _handleLanguageChange(String? value) {
    if (value != null) {
      HapticFeedback.lightImpact();
      setState(() {
        _selectedLang = value;
      });
      // Logic to actually change app locale would go here:
      // EasyLocalization.of(context)?.setLocale(Locale('en', 'US'));
      
      // Optional: Show a confirmation toast or snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Language changed to $value'),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: const Text(
          'Language',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: textColor),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(color: Colors.grey[200], height: 1),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _languages.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = _selectedLang == lang['name'];

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? primaryColor : Colors.transparent,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: RadioListTile<String>(
                    value: lang['name']!,
                    groupValue: _selectedLang,
                    onChanged: _handleLanguageChange,
                    activeColor: primaryColor,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text(
                      lang['name']!,
                      style: TextStyle(
                        color: textColor,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      lang['native']!,
                      style: const TextStyle(color: subTextColor, fontSize: 13),
                    ),
                    secondary: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor.withOpacity(0.1) : Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.translate_rounded,
                        size: 20,
                        color: isSelected ? primaryColor : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search language...',
          prefixIcon: const Icon(Icons.search, color: subTextColor),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}