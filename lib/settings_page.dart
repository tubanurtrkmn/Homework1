import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'services/user_settings_service.dart';
import 'services/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final UserSettingsService _settingsService = UserSettingsService();
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  bool _dailyReminders = true;
  bool _taskCompletedNotifications = true;
  bool _taskExpiredNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _settingsService.getUserSettings();
      setState(() {
        _selectedTime = TimeOfDay(
          hour: settings['notificationHour'] ?? 9,
          minute: settings['notificationMinute'] ?? 0,
        );
        _dailyReminders = settings['dailyReminders'] ?? true;
        _taskCompletedNotifications = settings['taskCompletedNotifications'] ?? true;
        _taskExpiredNotifications = settings['taskExpiredNotifications'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.green,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
      await _settingsService.updateNotificationTime(picked);
      
      // Kullanıcıya bilgi ver
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim saati ${_settingsService.timeToString(picked)} olarak ayarlandı'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _updateNotificationPreferences() async {
    await _settingsService.updateNotificationPreferences(
      dailyReminders: _dailyReminders,
      taskCompleted: _taskCompletedNotifications,
      taskExpired: _taskExpiredNotifications,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirim tercihleri güncellendi'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bildirim Ayarları Bölümü
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.notifications, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        const Text(
                          'Bildirim Ayarları',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Bildirim Saati
                    ListTile(
                      leading: const Icon(Icons.access_time, color: Colors.blue),
                      title: const Text('Günlük Bildirim Saati'),
                      subtitle: Text('Her gün ${_settingsService.timeToString(_selectedTime)} saatinde bildirim alacaksınız'),
                      trailing: ElevatedButton(
                        onPressed: _selectTime,
                        child: Text(_settingsService.timeToString(_selectedTime)),
                      ),
                      onTap: _selectTime,
                    ),
                    
                    const Divider(),
                    
                    // Bildirim Tercihleri
                    const Text(
                      'Bildirim Türleri',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    SwitchListTile(
                      title: const Text('Günlük Görev Hatırlatıcıları'),
                      subtitle: const Text('Uzun süreli görevler için günlük hatırlatmalar'),
                      value: _dailyReminders,
                      onChanged: (value) {
                        setState(() {
                          _dailyReminders = value;
                        });
                        _updateNotificationPreferences();
                      },
                      activeColor: Colors.green,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Görev Tamamlandı Bildirimleri'),
                      subtitle: const Text('Görev tamamlandığında bildirim al'),
                      value: _taskCompletedNotifications,
                      onChanged: (value) {
                        setState(() {
                          _taskCompletedNotifications = value;
                        });
                        _updateNotificationPreferences();
                      },
                      activeColor: Colors.green,
                    ),
                    
                    SwitchListTile(
                      title: const Text('Görev Süresi Doldu Bildirimleri'),
                      subtitle: const Text('Görev iptal edildiğinde bildirim al'),
                      value: _taskExpiredNotifications,
                      onChanged: (value) {
                        setState(() {
                          _taskExpiredNotifications = value;
                        });
                        _updateNotificationPreferences();
                      },
                      activeColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bilgi Kartı
            Card(
              color: Colors.blue.withOpacity(0.1),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Bildirimler, görevlerinizi unutmamanız ve düzenli hatırlatmalar almanız için tasarlanmıştır. Ayarlarınızı istediğiniz zaman değiştirebilirsiniz.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 