import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    // 1. Get the AuthProvider instance
    final auth = Provider.of<AuthProvider>(context);
    
    // 2. FIX: Access the public getter `currentUserEmail`
    final email = auth.currentUserEmail ?? 'Unknown'; 
    
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Column(
        children: [
          const SizedBox(height: 20),
          // Display the user's email
          Text('User: **$email**'), 
          
          ElevatedButton(
            onPressed: () async {
              // Perform the logout operation
              await auth.logout();
              
              // Navigate to the login screen after successful logout
              context.go('/login');
            }, 
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}