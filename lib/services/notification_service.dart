import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Initialize FCM + save token
  Future<void> init() async {
    try {
      // Request permission
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Notifications permission granted');
      } else {
        debugPrint('❌ Notifications permission denied');
        return;
      }

      // Get and save token
      final token = await _messaging.getToken();
      final uid = _auth.currentUser?.uid;

      if (uid != null && token != null) {
        await _saveToken(uid, token);
        debugPrint('✅ FCM Token saved: $token');
      }

      // Handle messages when app is in foreground
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      
      // Handle messages when app is in background but opened
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);
      
      // Handle messages when app is terminated
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpen(initialMessage);
      }
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .set({
          'fcmToken': token,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  /// Enable / Disable notifications at device level
  Future<void> setNotificationsEnabled(bool enabled) async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      if (enabled) {
        await _messaging.subscribeToTopic('all_users');
        await updateSettings({'notificationsEnabled': true});
        debugPrint('✅ Subscribed to notifications');
      } else {
        await _messaging.unsubscribeFromTopic('all_users');
        await updateSettings({'notificationsEnabled': false});
        debugPrint('🔕 Unsubscribed from notifications');
      }
    } catch (e) {
      debugPrint('❌ Error toggling notifications: $e');
    }
  }

  /// Save user preferences
  Future<void> updateSettings(Map<String, dynamic> data) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Notification settings updated: $data');
    } catch (e) {
      debugPrint('❌ Error updating settings: $e');
    }
  }

  /// Reset all notification settings to default
  Future<void> resetSettings() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      final defaultSettings = {
        'pauseAll': false,
        'eventReminders': true,
        'newEvents': true,
        'messages': true,
        'social': true,
        'marketing': false,
        'appUpdates': true,
        'quietStart': '22:00',
        'quietEnd': '08:00',
        'notificationsEnabled': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .set(defaultSettings, SetOptions(merge: true));
      
      // Resubscribe to topics
      await _messaging.subscribeToTopic('all_users');
      
      debugPrint('✅ Notification settings reset to default');
    } catch (e) {
      debugPrint('❌ Error resetting settings: $e');
    }
  }

  /// Send a test notification
  Future<void> sendTestNotification() async {
    try {
      final uid = _auth.currentUser?.uid;
      if (uid == null) return;

      // In a real app, you would call a Cloud Function to send a test notification
      // For now, just show a local notification simulation
      debugPrint('📱 Test notification would be sent to user: $uid');
      
      // Show a local dialog as simulation
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Stream settings
  Stream<Map<String, dynamic>?> getSettings() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('notifications')
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return doc.data();
          }
          // Return default settings if document doesn't exist
          return {
            'pauseAll': false,
            'eventReminders': true,
            'newEvents': true,
            'messages': true,
            'social': true,
            'marketing': false,
            'appUpdates': true,
          };
        });
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('📱 Foreground notification received');
    debugPrint('Title: ${message.notification?.title}');
    debugPrint('Body: ${message.notification?.body}');
    
    // You can show a local notification or in-app snackbar here
  }

  /// Handle message open
  void _handleMessageOpen(RemoteMessage message) {
    debugPrint('📱 Notification opened');
    debugPrint('Title: ${message.notification?.title}');
    
    // Handle navigation based on notification data
    final data = message.data;
    if (data.containsKey('type')) {
      switch (data['type']) {
        case 'event':
          // Navigate to event details
          debugPrint('Navigate to event: ${data['eventId']}');
          break;
        case 'message':
          // Navigate to chat
          debugPrint('Navigate to chat');
          break;
        default:
          break;
      }
    }
  }

  /// Subscribe to a specific topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      debugPrint('✅ Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('❌ Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('❌ Error unsubscribing from topic: $e');
    }
  }

  /// Delete FCM token (called on logout)
  Future<void> deleteToken() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('notifications')
          .update({
        'fcmToken': FieldValue.delete(),
      });
      
      debugPrint('✅ FCM token deleted');
    } catch (e) {
      debugPrint('❌ Error deleting token: $e');
    }
  }
}