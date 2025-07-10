import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'user_settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    print('🔧 Initializing notification service...');
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    
    // Android için bildirim kanalları oluştur
    await _createNotificationChannels();
    print('✅ Notification service initialized successfully!');
  }

  Future<void> _createNotificationChannels() async {
    print('📱 Creating notification channels...');
    
    // Test kanalı
    const AndroidNotificationChannel testChannel = AndroidNotificationChannel(
      'test_channel',
      'Test Kanalı',
      description: 'Test bildirimleri için',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Görev tamamlandı kanalı
    const AndroidNotificationChannel taskCompletedChannel = AndroidNotificationChannel(
      'task_completed',
      'Görev Tamamlandı',
      description: 'Görev tamamlandığında gönderilen bildirimler',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Görev hatırlatıcı kanalı
    const AndroidNotificationChannel taskRemindersChannel = AndroidNotificationChannel(
      'task_reminders',
      'Görev Hatırlatıcıları',
      description: 'Günlük görev hatırlatıcıları',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Görev süresi doldu kanalı
    const AndroidNotificationChannel taskExpiredChannel = AndroidNotificationChannel(
      'task_expired',
      'Görev Süresi Doldu',
      description: 'Görev süresi dolduğunda gönderilen bildirimler',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    // Seri hatırlatıcı kanalı
    const AndroidNotificationChannel streakReminderChannel = AndroidNotificationChannel(
      'streak_reminder',
      'Seri Hatırlatıcıları',
      description: 'Günlük seri devam ettirme hatırlatıcıları',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(testChannel);
      await androidPlugin.createNotificationChannel(taskCompletedChannel);
      await androidPlugin.createNotificationChannel(taskRemindersChannel);
      await androidPlugin.createNotificationChannel(taskExpiredChannel);
      await androidPlugin.createNotificationChannel(streakReminderChannel);
      print('✅ All notification channels created successfully!');
    } else {
      print('❌ Android plugin not available');
    }
  }

  Future<void> scheduleTaskReminder({
    required String taskId,
    required String taskTitle,
    required DateTime startDate,
    required int durationDays,
    required int maxPoints,
  }) async {
    // Kullanıcı ayarlarından bildirim saatini al
    final settingsService = UserSettingsService();
    final settings = await settingsService.getUserSettings();
    final notificationHour = settings['notificationHour'] ?? 9;
    final notificationMinute = settings['notificationMinute'] ?? 0;
    
    // Her gün kullanıcının seçtiği saatte bildirim gönder
    final scheduledTime = DateTime(startDate.year, startDate.month, startDate.day, notificationHour, notificationMinute);
    
    // Görev süresi boyunca her gün bildirim planla
    for (int day = 0; day < durationDays; day++) {
      final notificationTime = scheduledTime.add(Duration(days: day));
      
      // Eğer bildirim zamanı geçmişse, planlama
      if (notificationTime.isAfter(DateTime.now())) {
        final int notificationId = (taskId.hashCode.abs() + day) % 2147483647;
        await _notifications.zonedSchedule(
          notificationId,
          'Görev Hatırlatıcısı',
          'Göreviniz: $taskTitle\nSüre: ${durationDays - day} gün kaldı\nMaksimum Puan: $maxPoints\n💡 Erken tamamlayarak daha fazla puan kazanın!',
          tz.TZDateTime.from(notificationTime, tz.local),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders',
              'Görev Hatırlatıcıları',
              channelDescription: 'Günlük görev hatırlatıcıları',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  Future<void> cancelTaskReminders(String taskId, int durationDays) async {
    // Görevle ilgili tüm bildirimleri iptal et
    for (int day = 0; day < durationDays; day++) {
      final int notificationId = (taskId.hashCode.abs() + day) % 2147483647;
      await _notifications.cancel(notificationId);
    }
  }

  Future<void> sendTaskCompletedNotification({
    required String taskTitle,
    required int earnedPoints,
  }) async {
    print('🔔 Sending task completed notification...');
    print('Task title: $taskTitle, Points: $earnedPoints');
    
    try {
      final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      print('Notification ID: $notificationId');
      
      await _notifications.show(
        notificationId,
        'Görev Tamamlandı! 🎉',
        'Göreviniz: $taskTitle\nKazandığınız Puan: $earnedPoints',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'task_completed',
            'Görev Tamamlandı',
            channelDescription: 'Görev tamamlandığında gönderilen bildirimler',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
      print('✅ Notification sent successfully!');
    } catch (e) {
      print('❌ Error sending notification: $e');
    }
  }

  Future<void> sendTaskExpiredNotification({
    required String taskTitle,
  }) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'Görev Süresi Doldu ⏰',
      'Göreviniz: $taskTitle\nSüre doldu, görev iptal edildi.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'task_expired',
          'Görev Süresi Doldu',
          channelDescription: 'Görev süresi dolduğunda gönderilen bildirimler',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  Future<void> sendStreakReminderNotification(int currentStreak) async {
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '🔥 Serini Koru!',
      '$currentStreak günlük serini devam ettirmek için bugün de görev tamamla!',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Seri Hatırlatıcıları',
          channelDescription: 'Günlük seri devam ettirme hatırlatıcıları',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          enableVibration: true,
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }
} 