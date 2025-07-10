import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'draw_task_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'task_detail_page.dart';
import 'services/auth_service.dart';
import 'services/notification_service.dart';
import 'services/task_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'donation_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _selectedFilter = 'all'; // 'all', 'completed', 'cancelled', 'active'

  @override
  void initState() {
    super.initState();
    _updateTaskPoints();
    _autoCancelExpiredTasks();
  }

  Future<void> _updateTaskPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Önce tekrarlanan görevleri temizle
      await TaskService().cleanDuplicateTasks(user.uid);
      // Sonra puanları güncelle
      await TaskService().updateAllActiveTaskPoints(user.uid);
    }
  }

  Future<void> _autoCancelExpiredTasks() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await TaskService().autoCancelExpiredTasksAndPenalize(user.uid);
      // Seri kontrolü ve bildirim gönderme
      await TaskService().checkStreakAndNotify(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('user.uid: $user.uid');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.volunteer_activism),
            tooltip: 'Bağış Yap',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DonationPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profilim',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Giriş yapmadınız!'))
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  // Bu sayfa yenilemeyi tetikler
                });
                // Puanları güncelle
                await _updateTaskPoints();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Sade hoş geldin kartı
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || !snapshot.data!.exists) {
                        return const SizedBox.shrink();
                      }
                      final data = snapshot.data!.data() as Map<String, dynamic>;
                      final name = data['name'] ?? '';
                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        margin: const EdgeInsets.only(bottom: 18),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
                          child: Row(
                            children: [
                              Icon(Icons.waving_hand, color: Color(0xFF2ecc40), size: 36),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text('Hoş geldin, $name!', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  // Puan widgetı ve chart birlikte
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 48),
                                const SizedBox(height: 12),
                                const Text('Puanın', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                const SizedBox(height: 8),
                                Text('0', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.amber)),
                                const SizedBox(height: 8),
                                const Text('Henüz hiç görev tamamlamadın. Hadi ilk puanını kazan!', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                              ],
                            ),
                          ),
                        );
                      }
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      final totalPoints = userData['totalPoints'] ?? 0;
                      
                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('userTasks')
                            .where('users', isEqualTo: user.uid)
                            .where('status', isEqualTo: 'completed')
                            .snapshots(),
                        builder: (context, taskSnapshot) {
                          print('TaskSnapshot - hasData: ${taskSnapshot.hasData}, docs: ${taskSnapshot.data?.docs.length ?? 0}');
                          if (taskSnapshot.hasData && taskSnapshot.data!.docs.isNotEmpty) {
                            print('First task data: ${taskSnapshot.data!.docs.first.data()}');
                          }
                          
                          // Puan widget'ı - sağ üstte
                          Widget pointsWidget = Positioned(
                            top: 16,
                            right: 16,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.amber.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.amber.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$totalPoints',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                          
                          // Chart widget'ı
                          Widget chartWidget;
                          if (!taskSnapshot.hasData || taskSnapshot.data!.docs.isEmpty) {
                            chartWidget = const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart, color: Colors.grey, size: 48),
                                  SizedBox(height: 12),
                                  Text('Henüz tamamlanan görev yok', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                ],
                              ),
                            );
                          } else {
                            final docs = taskSnapshot.data!.docs;
                            print('Processing ${docs.length} completed tasks');
                            final Map<String, double> dailyPoints = {};
                            for (var doc in docs) {
                              print('Processing doc: ${doc.id}, data: ${doc.data()}');
                              final date = (doc['completedAt'] as Timestamp?)?.toDate();
                              if (date == null) {
                                print('Skipping doc ${doc.id} - no completedAt field');
                                // Eğer completedAt yoksa, assignedAt'ı kullan
                                final assignedDate = (doc['assignedAt'] as Timestamp?)?.toDate();
                                if (assignedDate == null) {
                                  print('Skipping doc ${doc.id} - no assignedAt field either');
                                  continue;
                                }
                                final dayKey = '${assignedDate.year}-${assignedDate.month.toString().padLeft(2, '0')}-${assignedDate.day.toString().padLeft(2, '0')}';
                                final points = (doc['currentPoints'] as num?)?.toDouble() ?? 0.0;
                                dailyPoints[dayKey] = (dailyPoints[dayKey] ?? 0) + points;
                                print('Added ${points} points for day $dayKey (using assignedAt)');
                              } else {
                                final dayKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                                final points = (doc['currentPoints'] as num?)?.toDouble() ?? 0.0;
                                dailyPoints[dayKey] = (dailyPoints[dayKey] ?? 0) + points;
                                print('Added ${points} points for day $dayKey (completedAt: $date)');
                              }
                            }
                            
                            // Bugünün tarihini kontrol et
                            final today = DateTime.now();
                            final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                            print('Today key: $todayKey');
                            print('Available keys: ${dailyPoints.keys.toList()}');
                            print('Today points: ${dailyPoints[todayKey]}');
                            
                            // Eğer bugün hiç puan yoksa, 0 olarak ekle
                            if (!dailyPoints.containsKey(todayKey)) {
                              dailyPoints[todayKey] = 0.0;
                              print('Added today with 0 points');
                            }
                            
                            // Son 7 günü göster
                            final last7Days = <String>[];
                            for (int i = 6; i >= 0; i--) {
                              final date = today.subtract(Duration(days: i));
                              final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                              last7Days.add(key);
                              if (!dailyPoints.containsKey(key)) {
                                dailyPoints[key] = 0.0;
                              }
                            }
                            
                            // Sadece son 7 günü kullan
                            final filteredDailyPoints = <String, double>{};
                            for (var key in last7Days) {
                              filteredDailyPoints[key] = dailyPoints[key] ?? 0.0;
                            }
                            dailyPoints.clear();
                            dailyPoints.addAll(filteredDailyPoints);
                            final sortedKeys = dailyPoints.keys.toList()..sort();
                            print('Final dailyPoints: $dailyPoints, sortedKeys: $sortedKeys');
                            
                            if (sortedKeys.isEmpty) {
                              chartWidget = const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bar_chart, color: Colors.grey, size: 48),
                                    SizedBox(height: 12),
                                    Text('Henüz tamamlanan görev yok', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                  ],
                                ),
                              );
                            } else {
                              chartWidget = Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Günlük Puan Dağılımı', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    height: 150,
                                    child: BarChart(
                                      BarChartData(
                                        alignment: BarChartAlignment.spaceAround,
                                        barTouchData: BarTouchData(enabled: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                            sideTitles: SideTitles(showTitles: true, reservedSize: 32),
                                          ),
                                          bottomTitles: AxisTitles(
                                            sideTitles: SideTitles(
                                              showTitles: true,
                                              getTitlesWidget: (value, meta) {
                                                final idx = value.toInt();
                                                if (idx < 0 || idx >= sortedKeys.length) return const SizedBox.shrink();
                                                final d = sortedKeys[idx].split('-');
                                                return Text('${d[2]}.${d[1]}', style: const TextStyle(fontSize: 10));
                                              },
                                              interval: 1,
                                            ),
                                          ),
                                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        gridData: FlGridData(show: true, drawVerticalLine: false),
                                        barGroups: [
                                          for (int i = 0; i < sortedKeys.length; i++)
                                            BarChartGroupData(
                                              x: i,
                                              barRods: [
                                                BarChartRodData(
                                                  toY: dailyPoints[sortedKeys[i]]!,
                                                  color: Colors.green,
                                                  width: 16,
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }
                          }
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                            elevation: 4,
                            child: SizedBox(
                              height: 220,
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: chartWidget,
                                  ),
                                  pointsWidget,
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  // Kompakt ve sade yeni görev butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        backgroundColor: Color(0xFF2ecc40),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      icon: const Icon(Icons.casino, color: Colors.white),
                      label: const Text(
                        'Yeni Görev',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const DrawTaskPage()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Başlık ve filtreleme
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Görevler:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.filter_list),
                        onSelected: (value) {
                          setState(() {
                            _selectedFilter = value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Row(
                              children: [
                                Icon(Icons.list, color: Colors.grey),
                                SizedBox(width: 8),
                                Text('Tümü'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'active',
                            child: Row(
                              children: [
                                Icon(Icons.play_circle, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Devam Edenler'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'completed',
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.green),
                                SizedBox(width: 8),
                                Text('Tamamlananlar'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'cancelled',
                            child: Row(
                              children: [
                                Icon(Icons.cancel, color: Colors.red),
                                SizedBox(width: 8),
                                Text('İptal Edilenler'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'expired',
                            child: Row(
                              children: [
                                Icon(Icons.timer_off, color: Colors.deepOrange),
                                SizedBox(width: 8),
                                Text('Süresi Dolanlar'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 500, // Yüksekliği artırdık
                    child: FutureBuilder<void>(
                      future: TaskService().updateAllActiveTaskPoints(user.uid),
                      builder: (context, updateSnapshot) {
                        return StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('userTasks')
                              .where('users', isEqualTo: user.uid)
                              .orderBy('assignedAt', descending: true)
                              .snapshots(),
                          builder: (context, snapshot) {
                            print('userTasks snapshot: ' + (snapshot.data?.docs.map((d) => d.data().toString()).toList().toString() ?? 'null'));
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                              return const Center(child: Text('Henüz hiç görevin yok.'));
                            }
                            
                            final userTasks = snapshot.data!.docs;
                            
                            // Filtreleme uygula
                            final filteredTasks = userTasks.where((userTask) {
                              final status = (userTask.data() as Map<String, dynamic>?)?['status'] ?? 'unknown';
                              final assignedAt = (userTask.data() as Map<String, dynamic>?)?['assignedAt']?.toDate();
                              final durationDays = (userTask.data() as Map<String, dynamic>?)?['durationDays'] ?? 1;
                              
                              // Süresi dolmuş görevleri kontrol et
                              bool isExpired = false;
                              if (assignedAt != null && status == 'active') {
                                final endDate = assignedAt.add(Duration(days: durationDays));
                                isExpired = DateTime.now().isAfter(endDate);
                              }
                              
                              switch (_selectedFilter) {
                                case 'completed':
                                  return status == 'completed';
                                case 'cancelled':
                                  return status == 'cancelled';
                                case 'active':
                                  return status == 'active' && !isExpired;
                                case 'expired':
                                  return status == 'active' && isExpired;
                                default:
                                  return true; // 'all' için tümü
                              }
                            }).toList();
                            
                            if (filteredTasks.isEmpty) {
                              String filterText = '';
                              switch (_selectedFilter) {
                                case 'completed':
                                  filterText = 'Tamamlanan görev yok';
                                  break;
                                case 'cancelled':
                                  filterText = 'İptal edilen görev yok';
                                  break;
                                case 'active':
                                  filterText = 'Devam eden görev yok';
                                  break;
                                case 'expired':
                                  filterText = 'Süresi dolan görev yok';
                                  break;
                                default:
                                  filterText = 'Henüz hiç görevin yok';
                              }
                              return Center(child: Text(filterText));
                            }
                            
                            for (var userTask in userTasks) {
                              final userTaskData = userTask.data() as Map<String, dynamic>;
                              print('userTask users: ' + userTaskData['users'].toString() + ', tasks: ' + userTaskData['tasks'].toString());
                            }
                            return ListView.builder(
                              itemCount: filteredTasks.length,
                              itemBuilder: (context, index) {
                                final userTask = filteredTasks[index];
                                final userTaskData = userTask.data() as Map<String, dynamic>;
                                return FutureBuilder<DocumentSnapshot>(
                                  future: FirebaseFirestore.instance.collection('tasks').doc(userTaskData['tasks']).get(),
                                  builder: (context, taskSnapshot) {
                                    if (!taskSnapshot.hasData || !taskSnapshot.data!.exists) {
                                      return const ListTile(title: Text('Görev bulunamadı'));
                                    }
                                    final taskData = taskSnapshot.data!.data() as Map<String, dynamic>;
                                    print('taskData: ' + taskData.toString());
                                    final status = userTaskData['status'] ?? 'unknown';
                                    Color statusColor;
                                    String statusLabel;
                                    switch (status) {
                                      case 'completed':
                                        statusColor = Colors.green;
                                        statusLabel = 'Tamamlandı';
                                        break;
                                      case 'cancelled':
                                        statusColor = Colors.red;
                                        statusLabel = 'Vazgeçildi';
                                        break;
                                      case 'expired':
                                        statusColor = Colors.deepOrange;
                                        statusLabel = 'Süresi Dolan';
                                        break;
                                      default:
                                        statusColor = Colors.orange;
                                        statusLabel = 'Devam Ediyor';
                                    }
                                    
                                    // Aktif görevler için puanı hesapla
                                    int currentPoints = userTaskData['currentPoints'] ?? userTaskData['maxPoints'] ?? taskData['maxPoints'];
                                    final maxPoints = userTaskData['maxPoints'] ?? taskData['maxPoints'];
                                    final minPoints = userTaskData['minPoints'] ?? taskData['minPoints'];
                                    final durationDays = userTaskData['durationDays'] ?? taskData['durationDays'];
                                    final assignedAt = userTaskData['assignedAt']?.toDate();
                                    
                                    // Süresi dolmuş görevleri kontrol et
                                    bool isExpired = false;
                                    if (assignedAt != null && status == 'active') {
                                      final endDate = assignedAt.add(Duration(days: durationDays));
                                      isExpired = DateTime.now().isAfter(endDate);
                                    }
                                    
                                    // Sadece aktif görevler için puanı hesapla
                                    if (status == 'active' && assignedAt != null) {
                                      currentPoints = TaskService().calculateCurrentPoints(
                                        assignedAt: assignedAt,
                                        maxPoints: maxPoints,
                                        minPoints: minPoints,
                                        durationDays: durationDays,
                                      );
                                    }
                                    
                                    // Süresi dolmuş görevler için özel durum
                                    if (isExpired) {
                                      statusColor = Colors.deepOrange;
                                      statusLabel = 'Süresi Dolan';
                                    }
                                    
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
                                      elevation: 3,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      child: ListTile(
                                        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        leading: CircleAvatar(
                                          backgroundColor: statusColor.withOpacity(0.15),
                                          child: Icon(Icons.assignment, color: statusColor),
                                        ),
                                        title: Text(
                                          taskData['title'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if ((taskData['description'] ?? '').toString().isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2.0, bottom: 4.0),
                                                child: Text(
                                                  (taskData['description'] as String).length > 60
                                                    ? (taskData['description'] as String).substring(0, 60) + '...'
                                                    : (taskData['description'] as String),
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            Row(
                                              children: [
                                                Chip(
                                                  label: Text(statusLabel, style: const TextStyle(color: Colors.white)),
                                                  backgroundColor: statusColor,
                                                  visualDensity: VisualDensity.compact,
                                                ),
                                                const SizedBox(width: 8),
                                                Icon(Icons.star, color: Colors.amber, size: 18),
                                                Text(' $currentPoints puan', style: const TextStyle(fontSize: 13)),
                                                if (status == 'active' && currentPoints < (userTaskData['maxPoints'] ?? taskData['maxPoints']))
                                                  Container(
                                                    margin: const EdgeInsets.only(left: 4),
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: Colors.orange[100],
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      '⏰',
                                                      style: TextStyle(fontSize: 10, color: Colors.orange[700]),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                            if (isExpired)
                                              Container(
                                                margin: const EdgeInsets.only(top: 4),
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: Colors.deepOrange[100],
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: Colors.deepOrange[300]!),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.warning, color: Colors.deepOrange[700], size: 14),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Süresi doldu! -5 puan eksiltilecek',
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: Colors.deepOrange[700],
                                                        fontWeight: FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => TaskDetailPage(
                                                taskData: taskData,
                                                userTaskData: userTask,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
  }
} 