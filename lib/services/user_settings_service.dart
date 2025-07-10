import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UserSettingsService {
  static final UserSettingsService _instance = UserSettingsService._internal();
  factory UserSettingsService() => _instance;
  UserSettingsService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kullanıcı ayarlarını getir
  Future<Map<String, dynamic>> getUserSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return _getDefaultSettings();

    try {
      final doc = await _firestore.collection('userSettings').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()!;
      } else {
        // Varsayılan ayarları oluştur
        final defaultSettings = _getDefaultSettings();
        await _firestore.collection('userSettings').doc(user.uid).set(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      print('Error getting user settings: $e');
      return _getDefaultSettings();
    }
  }

  // Kullanıcı ayarlarını güncelle
  Future<void> updateUserSettings(Map<String, dynamic> settings) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('userSettings').doc(user.uid).update(settings);
    } catch (e) {
      print('Error updating user settings: $e');
    }
  }

  // Bildirim saatini güncelle
  Future<void> updateNotificationTime(TimeOfDay time) async {
    final settings = await getUserSettings();
    settings['notificationHour'] = time.hour;
    settings['notificationMinute'] = time.minute;
    await updateUserSettings(settings);
  }

  // Bildirim tercihlerini güncelle
  Future<void> updateNotificationPreferences({
    required bool dailyReminders,
    required bool taskCompleted,
    required bool taskExpired,
  }) async {
    final settings = await getUserSettings();
    settings['dailyReminders'] = dailyReminders;
    settings['taskCompletedNotifications'] = taskCompleted;
    settings['taskExpiredNotifications'] = taskExpired;
    await updateUserSettings(settings);
  }

  // Varsayılan ayarlar
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'notificationHour': 9, // Sabah 9:00
      'notificationMinute': 0,
      'dailyReminders': true,
      'taskCompletedNotifications': true,
      'taskExpiredNotifications': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // TimeOfDay'i string'e çevir
  String timeToString(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // String'i TimeOfDay'e çevir
  TimeOfDay stringToTime(String timeString) {
    final parts = timeString.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }
} 