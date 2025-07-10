import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_service.dart';
import 'user_settings_service.dart';

class TaskService {
  final tasksCollection = FirebaseFirestore.instance.collection('tasks');
  final userTasksCollection = FirebaseFirestore.instance.collection('userTasks');

  // Görev puanını zamanla azaltarak hesapla
  int calculateCurrentPoints({
    required DateTime assignedAt,
    required int maxPoints,
    required int minPoints,
    required int durationDays,
  }) {
    final now = DateTime.now();
    final endDate = assignedAt.add(Duration(days: durationDays));
    
    // Eğer süre dolmuşsa minimum puanı döndür
    if (now.isAfter(endDate)) {
      return minPoints;
    }
    
    // Geçen süreyi hesapla
    final elapsedDays = now.difference(assignedAt).inDays;
    final totalDays = durationDays;
    
    // Puan azalmasını hesapla (doğrusal azalma)
    final pointReduction = ((maxPoints - minPoints) * elapsedDays) / totalDays;
    final currentPoints = maxPoints - pointReduction;
    
    // Minimum puanın altına düşmemesi için kontrol et
    return currentPoints.round().clamp(minPoints, maxPoints);
  }

  // Görev puanını güncelle
  Future<void> updateTaskPoints(String userTaskId) async {
    final userTaskDoc = await userTasksCollection.doc(userTaskId).get();
    if (!userTaskDoc.exists) return;
    
    final data = userTaskDoc.data()!;
    final assignedAt = data['assignedAt']?.toDate() as DateTime?;
    final taskId = data['tasks'];
    final taskDoc = await tasksCollection.doc(taskId).get();
    final taskData = taskDoc.data() ?? {};
    final maxPoints = data['maxPoints'] ?? data['currentPoints'] ?? taskData['maxPoints'];
    final minPoints = data['minPoints'] ?? taskData['minPoints'];
    final durationDays = data['durationDays'] ?? taskData['durationDays'] ?? 1;
    final status = data['status'] ?? 'active';
    
    // Sadece aktif görevler için puan güncelle
    if (status == 'active' && assignedAt != null) {
      final currentPoints = calculateCurrentPoints(
        assignedAt: assignedAt,
        maxPoints: maxPoints,
        minPoints: minPoints,
        durationDays: durationDays,
      );
      
      await userTasksCollection.doc(userTaskId).update({
        'currentPoints': currentPoints,
      });
    }
  }

  // Tüm aktif görevlerin puanlarını güncelle
  Future<void> updateAllActiveTaskPoints(String userId) async {
    final userTasksSnapshot = await userTasksCollection
        .where('users', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();
    
    for (var doc in userTasksSnapshot.docs) {
      await updateTaskPoints(doc.id);
    }
  }

  // Görev ekle
  Future<void> addTask({
    required String title,
    required String description,
    required int maxPoints,
    required int minPoints,
    required int durationDays,
    String? imageUrl,
  }) async {
    await tasksCollection.add({
      'title': title,
      'description': description,
      'maxPoints': maxPoints,
      'minPoints': minPoints,
      'durationDays': durationDays,
      'createdAt': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl ?? '',
    });
  }

  // Kullanıcıya görev ata
  Future<void> assignTaskToUser({
    required String userId,
    required String taskId,
    required int maxPoints,
    required int minPoints,
    required int durationDays,
  }) async {
    final docRef = await userTasksCollection.add({
      'users': userId,
      'tasks': taskId,
      'assignedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
      'currentPoints': maxPoints,
      'maxPoints': maxPoints, // Maksimum puanı da sakla
      'status': 'active',
      'minPoints': minPoints,
      'durationDays': durationDays,
    });

    // Görev başlığını al
    final taskDoc = await tasksCollection.doc(taskId).get();
    final taskTitle = taskDoc.data()?['title'] ?? 'Bilinmeyen Görev';

    // Kullanıcı ayarlarını kontrol et
    final settingsService = UserSettingsService();
    final settings = await settingsService.getUserSettings();
    
    // Bildirimleri planla (eğer görev süresi 1 günden fazlaysa ve günlük hatırlatmalar açıksa)
    if (durationDays > 1 && settings['dailyReminders'] == true) {
      await NotificationService().scheduleTaskReminder(
        taskId: docRef.id,
        taskTitle: taskTitle,
        startDate: DateTime.now(),
        durationDays: durationDays,
        maxPoints: maxPoints,
      );
    }
  }

  // Süresi dolan görevleri kontrol et ve otomatik iptal et (puan eksilt)
  Future<void> autoCancelExpiredTasksAndPenalize(String userId) async {
    final now = DateTime.now();
    final userTasksSnapshot = await userTasksCollection
        .where('users', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();

    for (var doc in userTasksSnapshot.docs) {
      final data = doc.data();
      final assignedAt = data['assignedAt']?.toDate() as DateTime?;
      final durationDays = data['durationDays'] ?? 1;
      if (assignedAt != null) {
        final endDate = assignedAt.add(Duration(days: durationDays));
        if (now.isAfter(endDate)) {
          // Görev süresi dolmuş ve hala aktifse, otomatik iptal et ve 5 puan eksilt
          await updateUserTaskStatus(
            userTaskId: doc.id,
            status: 'cancelled',
            penalize: true,
            penaltyPoints: 5,
          );
        }
      }
    }
  }

  // Kullanıcıya atanmış görevin durumunu güncelle
  Future<void> updateUserTaskStatus({
    required String userTaskId,
    required String status,
    bool penalize = false,
    int penaltyPoints = 0,
  }) async {
    print('updateUserTaskStatus başladı: userTaskId=$userTaskId, status=$status, penalize=$penalize, penaltyPoints=$penaltyPoints');
    final userTaskDoc = await userTasksCollection.doc(userTaskId).get();
    if (!userTaskDoc.exists) {
      print('HATA: userTask dokümanı bulunamadı: $userTaskId');
      throw Exception('Görev bulunamadı');
    }
    final userTaskData = userTaskDoc.data()!;
    final userId = userTaskData['users'];
    final durationDays = userTaskData['durationDays'] ?? 1;
    print('userTaskData: $userTaskData');
    print('userId: $userId, durationDays: $durationDays');
    int points = userTaskData['currentPoints'] ?? 0;
    if (status == 'completed') {
      final assignedAt = userTaskData['assignedAt']?.toDate() as DateTime?;
      final maxPoints = userTaskData['maxPoints'] ?? userTaskData['currentPoints'] ?? 0;
      final minPoints = userTaskData['minPoints'] ?? 0;
      final taskDurationDays = userTaskData['durationDays'] ?? 1;
      print('assignedAt: $assignedAt, maxPoints: $maxPoints, minPoints: $minPoints, taskDurationDays: $taskDurationDays');
      if (assignedAt != null) {
        points = calculateCurrentPoints(
          assignedAt: assignedAt,
          maxPoints: maxPoints,
          minPoints: minPoints,
          durationDays: taskDurationDays,
        );
        print('Hesaplanan puan: $points');
      }
    }
    final updateData = <String, dynamic>{'status': status};
    if (status == 'completed') {
      updateData['completedAt'] = FieldValue.serverTimestamp();
      updateData['currentPoints'] = points; // Güncel puanı da güncelle
      print('Görev tamamlandı, puan: $points, taskId: ${userTaskData['tasks']}');
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      try {
        await userDoc.update({
          'totalPoints': FieldValue.increment(points),
          'completedTasks': FieldValue.arrayUnion([userTaskData['tasks']])
        });
        print('Kullanıcı puanı güncellendi: +$points puan');
        
        // Seri sistemini güncelle
        await updateStreak(userId);
      } catch (e) {
        print('Kullanıcı puanı güncellenirken hata: $e');
        throw e;
      }
      await NotificationService().cancelTaskReminders(userTaskId, durationDays);
    } else if (status == 'cancelled') {
      updateData['completedAt'] = FieldValue.serverTimestamp();
      final settingsService = UserSettingsService();
      final settings = await settingsService.getUserSettings();
      if (settings['taskExpiredNotifications'] == true) {
        final taskDoc = await tasksCollection.doc(userTaskDoc['tasks']).get();
        final taskTitle = taskDoc.data()?['title'] ?? 'Bilinmeyen Görev';
        await NotificationService().sendTaskExpiredNotification(taskTitle: taskTitle);
      }
      await NotificationService().cancelTaskReminders(userTaskId, durationDays);
      // Eğer penalize true ise, kullanıcıdan puan eksilt
      if (penalize && penaltyPoints > 0) {
        final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
        try {
          await userDoc.update({
            'totalPoints': FieldValue.increment(-penaltyPoints),
          });
          print('Kullanıcıdan $penaltyPoints puan eksiltildi.');
        } catch (e) {
          print('Kullanıcıdan puan eksiltme hatası: $e');
        }
      }
    }
    print('userTask dokümanı güncelleniyor: $updateData');
    await userTasksCollection.doc(userTaskId).update(updateData);
    print('userTask dokümanı güncellendi');
  }

  // Tekrarlanan görevleri temizle
  Future<void> cleanDuplicateTasks(String userId) async {
    print('Tekrarlanan görevler temizleniyor...');
    
    final userTasksSnapshot = await userTasksCollection
        .where('users', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();
    
    final Map<String, List<String>> taskGroups = {};
    
    // Aynı taskId'ye sahip görevleri grupla
    for (var doc in userTasksSnapshot.docs) {
      final taskId = doc.data()['tasks'] as String;
      if (!taskGroups.containsKey(taskId)) {
        taskGroups[taskId] = [];
      }
      taskGroups[taskId]!.add(doc.id);
    }
    
    // Her grupta birden fazla görev varsa, ilkini tut diğerlerini sil
    for (var taskId in taskGroups.keys) {
      final docs = taskGroups[taskId]!;
      if (docs.length > 1) {
        print('Task $taskId için ${docs.length} tekrarlanan görev bulundu');
        
        // İlk görevi tut, diğerlerini sil
        for (int i = 1; i < docs.length; i++) {
          await userTasksCollection.doc(docs[i]).delete();
          print('Tekrarlanan görev silindi: ${docs[i]}');
        }
      }
    }
    
    print('Tekrarlanan görevler temizlendi');
  }

  // Seri sistemini güncelle
  Future<void> updateStreak(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final userData = await userDoc.get();
    
    if (!userData.exists) return;
    
    final data = userData.data()!;
    final currentStreak = data['streak'] ?? 0;
    final lastCompletedDate = data['lastCompletedDate']?.toDate();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Eğer son tamamlanan tarih bugünse, seri zaten güncellenmiş
    if (lastCompletedDate != null) {
      final lastDate = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
      if (lastDate.isAtSameMomentAs(todayDate)) {
        return;
      }
    }
    
    // Eğer son tamamlanan tarih dünse, seriyi artır
    if (lastCompletedDate != null) {
      final lastDate = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
      final yesterday = todayDate.subtract(const Duration(days: 1));
      
      if (lastDate.isAtSameMomentAs(yesterday)) {
        // Seri devam ediyor
        await userDoc.update({
          'streak': currentStreak + 1,
          'lastCompletedDate': FieldValue.serverTimestamp(),
        });
        print('Seri güncellendi: ${currentStreak + 1} gün');
      } else if (lastDate.isBefore(yesterday)) {
        // Seri kırıldı, yeniden başla
        await userDoc.update({
          'streak': 1,
          'lastCompletedDate': FieldValue.serverTimestamp(),
        });
        print('Seri yeniden başladı: 1 gün');
      }
    } else {
      // İlk görev tamamlama
      await userDoc.update({
        'streak': 1,
        'lastCompletedDate': FieldValue.serverTimestamp(),
      });
      print('İlk seri başladı: 1 gün');
    }
  }

  // Seri kontrolü ve bildirim gönderme
  Future<void> checkStreakAndNotify(String userId) async {
    final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
    final userData = await userDoc.get();
    
    if (!userData.exists) return;
    
    final data = userData.data()!;
    final currentStreak = data['streak'] ?? 0;
    final lastCompletedDate = data['lastCompletedDate']?.toDate();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    
    // Eğer bugün henüz görev tamamlanmamışsa ve seri varsa, bildirim gönder
    if (currentStreak > 0 && lastCompletedDate != null) {
      final lastDate = DateTime(lastCompletedDate.year, lastCompletedDate.month, lastCompletedDate.day);
      
      if (lastDate.isBefore(todayDate)) {
        // Seri devam etmek için bugün görev tamamla
        final settingsService = UserSettingsService();
        final settings = await settingsService.getUserSettings();
        
        if (settings['dailyReminders'] == true) {
          await NotificationService().sendStreakReminderNotification(currentStreak);
        }
      }
    }
  }
} 