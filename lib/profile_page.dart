import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/auth_service.dart';
import 'services/task_service.dart';
import 'settings_page.dart';

// Rozet modeli
class Badge {
  final String name;
  final String description;
  final IconData icon;
  final int requiredPoints;
  final Color color;

  Badge({
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredPoints,
    required this.color,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Rozet listesi
  final List<Badge> badges = [
    Badge(
      name: 'Başlangıç',
      description: 'İlk görevini tamamladın!',
      icon: Icons.star,
      requiredPoints: 50,
      color: Colors.amber,
    ),
    Badge(
      name: 'Çalışkan',
      description: '150 puan topladın!',
      icon: Icons.work,
      requiredPoints: 150,
      color: Colors.blue,
    ),
    Badge(
      name: 'Azimli',
      description: '300 puan topladın!',
      icon: Icons.fitness_center,
      requiredPoints: 300,
      color: Colors.green,
    ),
    Badge(
      name: 'Uzman',
      description: '600 puan topladın!',
      icon: Icons.psychology,
      requiredPoints: 600,
      color: Colors.purple,
    ),
    Badge(
      name: 'Usta',
      description: '1000 puan topladın!',
      icon: Icons.auto_awesome,
      requiredPoints: 1000,
      color: Colors.orange,
    ),
    Badge(
      name: 'Efsane',
      description: '1500 puan topladın!',
      icon: Icons.diamond,
      requiredPoints: 1500,
      color: Colors.red,
    ),
    Badge(
      name: 'Kahraman',
      description: '2000 puan topladın!',
      icon: Icons.emoji_events,
      requiredPoints: 2000,
      color: Colors.indigo,
    ),
    Badge(
      name: 'Efsanevi',
      description: '2500 puan topladın!',
      icon: Icons.workspace_premium,
      requiredPoints: 2500,
      color: Colors.teal,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _updateTaskPoints();
  }

  Future<void> _updateTaskPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await TaskService().updateAllActiveTaskPoints(user.uid);
    }
  }

  // Rozet kazanılıp kazanılmadığını kontrol et
  bool isBadgeEarned(Badge badge, int userPoints) {
    return userPoints >= badge.requiredPoints;
  }

  // Sonraki rozet için kalan puanı hesapla
  int getRemainingPoints(Badge badge, int userPoints) {
    return badge.requiredPoints - userPoints;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print('profile user.uid: $user?.uid');

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmadınız!')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profilim')),
      body: RefreshIndicator(
        onRefresh: () async {
          // Puanları güncelle
          await _updateTaskPoints();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Center(child: Text('Kullanıcı verisi bulunamadı.'));
              }
              var data = snapshot.data!.data() as Map<String, dynamic>;
              final userPoints = data['totalPoints'] ?? 0;
              
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('userTasks')
                    .where('users', isEqualTo: user.uid)
                    .where('status', isEqualTo: 'completed')
                    .get(),
                builder: (context, completedTasksSnapshot) {
                  final completedTasksCount = completedTasksSnapshot.data?.docs.length ?? 0;
                  
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Profil kartı
                        Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                          elevation: 8,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 28),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: const Color(0xFF00bfff),
                                  child: Icon(Icons.person, size: 54, color: Colors.white),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  data['name'] ?? '',
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  data['mail'] ?? '',
                                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                                ),
                                const SizedBox(height: 24),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.green, size: 32),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$completedTasksCount',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Tamamlanan', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(Icons.star, color: Colors.amber, size: 32),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$userPoints',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Puan', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            color: Colors.purple[500],
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.local_fire_department,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${data['streak'] ?? 0}',
                                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                        ),
                                        const Text('Günlük Seri', style: TextStyle(fontSize: 14)),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 24),
                                // Seri motivasyon mesajı
                                if ((data['streak'] ?? 0) > 0)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Colors.purple[100]!, Colors.blue[100]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.purple[300]!),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.emoji_events, color: Colors.purple[700], size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '${data['streak']} günlük serini devam ettirmek için bugün de görev tamamla! 🔥',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.purple[700],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Rozetler bölümü
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'Rozetlerim',
                                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                GridView.builder(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.8,
                                  ),
                                  itemCount: badges.length,
                                  itemBuilder: (context, index) {
                                    final badge = badges[index];
                                    final isEarned = isBadgeEarned(badge, userPoints);
                                    final remainingPoints = getRemainingPoints(badge, userPoints);
                                    
                                    return Card(
                                      elevation: isEarned ? 4 : 1,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        side: BorderSide(
                                          color: isEarned ? badge.color : Colors.grey[300]!,
                                          width: isEarned ? 2 : 1,
                                        ),
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(16),
                                        onTap: () {
                                          _showBadgeDetails(badge, isEarned, remainingPoints, userPoints);
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isEarned ? badge.color.withOpacity(0.1) : Colors.grey[100],
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  badge.icon,
                                                  size: 32,
                                                  color: isEarned ? badge.color : Colors.grey[400],
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                badge.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: isEarned ? badge.color : Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 4),
                                              if (!isEarned)
                                                Text(
                                                  '$remainingPoints puan kaldı',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.grey[500],
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              if (isEarned)
                                                Icon(
                                                  Icons.check_circle,
                                                  color: badge.color,
                                                  size: 16,
                                                ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Butonlar
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.settings),
                            label: const Text('Ayarlar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const SettingsPage()),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.logout),
                            label: const Text('Çıkış Yap'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              AuthService().signOut(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showBadgeDetails(Badge badge, bool isEarned, int remainingPoints, int userPoints) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isEarned ? badge.color.withOpacity(0.1) : Colors.grey[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                badge.icon,
                color: isEarned ? badge.color : Colors.grey[400],
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                badge.name,
                style: TextStyle(
                  color: isEarned ? badge.color : Colors.grey[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              badge.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            if (isEarned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: badge.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: badge.color, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Kazanıldı!',
                      style: TextStyle(
                        color: badge.color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.timer, color: Colors.orange[700], size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$remainingPoints puan kaldı',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: userPoints / badge.requiredPoints,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                isEarned ? badge.color : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$userPoints / ${badge.requiredPoints} puan',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }
} 