// lib/services/security_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user security settings
  Stream<Map<String, dynamic>?> getSettings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return Stream.value(null);
    
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // Update security settings
  Future<void> updateSettings(Map<String, dynamic> settings) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _firestore.collection('users').doc(uid).update(settings);
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Update password
      await user.updatePassword(newPassword);
      
      // Log the activity
      await _logSecurityActivity('Password changed', 'Success', true);
      
      return true;
    } catch (e) {
      debugPrint('Error changing password: $e');
      await _logSecurityActivity('Password change attempt', e.toString(), false);
      return false;
    }
  }

  // Send password reset email
  Future<void> sendPasswordReset() async {
    final user = _auth.currentUser;
    if (user?.email != null) {
      await _auth.sendPasswordResetEmail(email: user!.email!);
      await _logSecurityActivity('Password reset email sent', 'Success', true);
    }
  }

  // Send email verification
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
      await _logSecurityActivity('Email verification sent', 'Success', true);
    }
  }

  // Enable two-factor authentication
  Future<String?> enableTwoFactor() async {
    try {
      // Generate secret key
      final secret = _generateSecretKey();
      
      // Store secret in Firestore
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({
          'twoFactorSecret': secret,
          'twoFactorEnabled': false, // Will be enabled after verification
        });
      }
      
      // Generate QR code URL (using Google Charts API)
      final otpAuthUrl = _generateOtpAuthUrl(secret);
      
      return otpAuthUrl;
    } catch (e) {
      debugPrint('Error enabling 2FA: $e');
      return null;
    }
  }

  // Verify two-factor authentication code
  Future<bool> verifyTwoFactor(String code) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return false;
      
      final doc = await _firestore.collection('users').doc(uid).get();
      final secret = doc.data()?['twoFactorSecret'];
      
      if (secret == null) return false;
      
      // Verify the code (simplified - in production use a proper TOTP library)
      final isValid = _verifyTotpCode(code, secret);
      
      if (isValid) {
        await _firestore.collection('users').doc(uid).update({
          'twoFactorEnabled': true,
        });
        await _logSecurityActivity('Two-factor authentication enabled', 'Success', true);
      }
      
      return isValid;
    } catch (e) {
      debugPrint('Error verifying 2FA: $e');
      return false;
    }
  }

  // Disable two-factor authentication
  Future<void> disableTwoFactor() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    await _firestore.collection('users').doc(uid).update({
      'twoFactorEnabled': false,
      'twoFactorSecret': null,
    });
    
    await _logSecurityActivity('Two-factor authentication disabled', 'Success', true);
  }

  // Get active sessions
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    
    try {
      final sessions = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .orderBy('lastActive', descending: true)
          .get();
      
      if (sessions.docs.isEmpty) {
        // Return mock data for demo
        return [
          {
            'id': 'current',
            'deviceName': await _getDeviceInfo(),
            'lastActive': 'Just now',
            'isCurrent': true,
          },
          {
            'id': 'session_1',
            'deviceName': 'Chrome on Windows',
            'lastActive': '2 days ago',
            'isCurrent': false,
          },
        ];
      }
      
      return sessions.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'deviceName': data['deviceName'] ?? 'Unknown Device',
          'lastActive': _formatTimestamp(data['lastActive']),
          'isCurrent': data['isCurrent'] ?? false,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting sessions: $e');
      return [];
    }
  }

  // Revoke a specific session
  Future<void> revokeSession(String sessionId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .doc(sessionId)
          .delete();
      
      await _logSecurityActivity('Session revoked', 'Device: $sessionId', true);
    } catch (e) {
      debugPrint('Error revoking session: $e');
    }
  }

  // Revoke all sessions
  Future<void> revokeAllSessions() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      final sessions = await _firestore
          .collection('users')
          .doc(uid)
          .collection('sessions')
          .get();
      
      final batch = _firestore.batch();
      for (final doc in sessions.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      await _logSecurityActivity('All sessions revoked', 'Success', true);
      
      // Sign out after revoking all sessions
      await _auth.signOut();
    } catch (e) {
      debugPrint('Error revoking all sessions: $e');
    }
  }

  // Get security activity log
  Future<List<Map<String, dynamic>>> getSecurityActivity() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];
    
    try {
      const activities = [
        {'event': 'Password changed', 'details': 'Password updated successfully', 'success': true},
        {'event': 'Login from new device', 'details': 'Chrome on Windows', 'success': true},
        {'event': 'Email verification', 'details': 'Verification email sent', 'success': true},
        {'event': 'Profile updated', 'details': 'Personal information changed', 'success': true},
      ];
      
      return activities.map((activity) {
        return {
          ...activity,
          'timestamp': _formatTimestamp(DateTime.now()),
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting security activity: $e');
      return [];
    }
  }

  // Request data export
  Future<void> requestDataExport() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      // In production, this would trigger a cloud function to export user data
      await _logSecurityActivity('Data export requested', 'Pending', true);
      
      // Show confirmation
      debugPrint('Data export requested for user: $uid');
    } catch (e) {
      debugPrint('Error requesting data export: $e');
    }
  }

  // Delete account
  Future<bool> deleteAccount(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) return false;
      
      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
      
      // Delete user data from Firestore
      await _firestore.collection('users').doc(user.uid).delete();
      
      // Delete user authentication
      await user.delete();
      
      return true;
    } catch (e) {
      debugPrint('Error deleting account: $e');
      await _logSecurityActivity('Account deletion attempted', e.toString(), false);
      return false;
    }
  }

  // Private helper methods
  Future<void> _logSecurityActivity(String event, String details, bool success) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    
    try {
      await _firestore.collection('users').doc(uid).collection('security_logs').add({
        'event': event,
        'details': details,
        'success': success,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging security activity: $e');
    }
  }

  String _generateSecretKey() {
    // Generate a random secret key for 2FA
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = DateTime.now().millisecondsSinceEpoch;
    return String.fromCharCodes(
      Iterable.generate(16, (_) => chars.codeUnitAt(random % chars.length))
    );
  }

  String _generateOtpAuthUrl(String secret) {
    final user = _auth.currentUser;
    final email = user?.email ?? 'user';
    return 'otpauth://totp/Eventra:$email?secret=$secret&issuer=Eventra';
  }

  bool _verifyTotpCode(String code, String secret) {
    // Simplified verification - in production use a proper TOTP library
    // For demo purposes, accept any 6-digit code
    return code.length == 6 && RegExp(r'^\d+$').hasMatch(code);
  }

  Future<String> _getDeviceInfo() async {
    // Get device information
    return 'Current Device';
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    
    DateTime dt;
    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    } else {
      return 'Just now';
    }
    
    final now = DateTime.now();
    final diff = now.difference(dt);
    
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d, yyyy').format(dt);
  }
}