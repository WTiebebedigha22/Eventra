import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const Color primaryPink = Color(0xFFE91E63); 
  static const Color secondaryPurple = Color(0xFF9C27B0);
  static const Color backgroundColor = Colors.black;
  static const Color navBarColor = Color(0xFF181818); 
  static const Color textColor = Colors.white;

  int _index = 0;
  final tabs = ['/home/explore', '/home/chat', '/home/profile'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
    });
  }

  void _onTap(int i) {
    setState(() => _index = i);
    context.go(tabs[i]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: const SafeArea(
        child: Center(
          child: Text(
            'Explore Events',
            style: TextStyle(color: textColor, fontSize: 20),
          ),
        ),
      ),
      
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
        ),
        child: BottomNavigationBar(
          currentIndex: _index,
          onTap: _onTap,
          
          // Spotify Aesthetic Settings:
          backgroundColor: navBarColor, // Very dark background
          selectedItemColor: primaryPink, // Vibrant accent color
          unselectedItemColor: textColor.withOpacity(0.7), // Faded unselected icons
          type: BottomNavigationBarType.fixed, // Ensure the background color covers the entire bar
          showUnselectedLabels: true, // Show labels for clarity
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),

          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.explore), label: 'Explore'),
            BottomNavigationBarItem(
                icon: Icon(Icons.chat_bubble), label: 'Chats'),
            BottomNavigationBarItem(
                icon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}