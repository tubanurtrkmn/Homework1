import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/task_service.dart';
import 'home_page.dart';

class DrawTaskPage extends StatefulWidget {
  const DrawTaskPage({Key? key}) : super(key: key);

  @override
  State<DrawTaskPage> createState() => _DrawTaskPageState();
}

class _DrawTaskPageState extends State<DrawTaskPage> {
  bool _isLoading = false;
  Map<String, dynamic>? _selectedTask;
  List<Map<String, dynamic>> _allTasks = [];
  int _currentIndex = 0;
  Timer? _animationTimer;
  bool _isAnimating = false;
  bool _taskAccepted = false;
  bool _isAcceptingTask = false; // Görev kabul etme durumu

  Future<void> _startDrawAnimation() async {
    setState(() {
      _isLoading = true;
      _isAnimating = false;
      _taskAccepted = false;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _isAnimating = false;
        });
        return;
      }

      // Kullanıcıya atanmış görevlerin ID'lerini çek
      final userTasksSnapshot = await FirebaseFirestore.instance
          .collection('userTasks')
          .where('users', isEqualTo: user.uid)
          .get();
      final assignedTaskIds = userTasksSnapshot.docs
          .map((doc) => doc['tasks'] as String)
          .toSet();

      // Tüm görevleri çek ve atanmış olanları çıkar
      final tasksSnapshot = await FirebaseFirestore.instance.collection('tasks').get();
      final tasks = tasksSnapshot.docs
          .where((doc) => !assignedTaskIds.contains(doc.id))
          .map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          })
          .toList();

      // Seçili görev varsa, onu da çıkar (aynı görev tekrar gelmesin)
      if (_selectedTask != null) {
        tasks.removeWhere((task) => task['id'] == _selectedTask!['id']);
      }

      if (tasks.isEmpty) {
        setState(() {
          _isLoading = false;
          _isAnimating = false;
          _selectedTask = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Çekilecek yeni görev kalmadı!')),
        );
        return;
      }

      _allTasks = tasks;
      _currentIndex = 0;
      setState(() {
        _isAnimating = true;
      });

      // Animasyonu başlat (daha yavaş)
      _animationTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % _allTasks.length;
        });
      });

      // 2 saniye sonra animasyonu durdur
      await Future.delayed(const Duration(seconds: 2));
      _animationTimer?.cancel();

      final selectedTask = _allTasks[_currentIndex];

      setState(() {
        _selectedTask = selectedTask;
        _isLoading = false;
        _isAnimating = false;
        _taskAccepted = false;
      });
    } catch (e) {
      _animationTimer?.cancel();
      setState(() {
        _isLoading = false;
        _isAnimating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Görevler yüklenemedi: $e')),
      );
    }
  }

  Future<void> _acceptTask() async {
    // Eğer zaten görev kabul ediliyorsa, işlemi engelle
    if (_isAcceptingTask) {
      print('Görev kabul etme zaten devam ediyor');
      return;
    }
    
    try {
      setState(() {
        _isAcceptingTask = true;
      });
      
      print('Görev kabul etme başladı');
      
    final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        print('HATA: Kullanıcı giriş yapmamış');
        return;
      }
      
      if (_selectedTask == null) {
        print('HATA: Seçili görev yok');
        return;
      }
      
      print('Seçili görev: ${_selectedTask!}');
      
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
      
      final taskService = TaskService();
      await taskService.assignTaskToUser(
        userId: user.uid,
        taskId: _selectedTask!['id'],
        maxPoints: _selectedTask!['maxPoints'],
        minPoints: _selectedTask!['minPoints'],
        durationDays: _selectedTask!['durationDays'],
      );
      
      print('Görev başarıyla atandı');
      
      // Loading'i kapat
      Navigator.of(context).pop();
      
      setState(() {
        _taskAccepted = true;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Görev başarıyla alındı!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Ana sayfaya yönlendir
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
      
    } catch (e) {
      print('Görev kabul etme hatası: $e');
      
      // Loading'i kapat
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isAcceptingTask = false;
      });
    }
  }

  Widget _buildInfoChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _animationTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Görev Seç')),
      body: Center(
        child: _isLoading
            ? const CircularProgressIndicator()
            : _selectedTask == null
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Basit ve temiz tasarım
                        Icon(
                          Icons.casino,
                          size: 80,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Yeni Görev',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Rastgele bir çevre görevi seçin',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 40),
                        // Ana buton
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: _isAnimating ? null : _startDrawAnimation,
                            icon: const Icon(Icons.casino, color: Colors.white, size: 28),
                            label: const Text(
                              'Görev Seç',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Seçilen görev kartı - daha kompakt
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                Icon(Icons.emoji_events, size: 36, color: Colors.green.shade600),
                                const SizedBox(height: 12),
                                Text(
                                  _selectedTask!['title'] ?? '',
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  constraints: const BoxConstraints(maxHeight: 80),
                                  child: SingleChildScrollView(
                                    child: Text(
                                  _selectedTask!['description'] ?? '',
                                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Puan bilgileri - daha kompakt
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildInfoChip('Maksimum', '${_selectedTask!['maxPoints']}', Colors.amber),
                                    _buildInfoChip('Minimum', '${_selectedTask!['minPoints']}', Colors.red),
                                    _buildInfoChip('Süre', '${_selectedTask!['durationDays']} gün', Colors.blue),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blue[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Görev süresi doldukça puan azalır. Erken tamamlayarak maksimum puanı kazanın!',
                                          style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (!_taskAccepted) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _startDrawAnimation,
                                  icon: const Icon(Icons.refresh, size: 20),
                                  label: const Text('Yeni Seç', style: TextStyle(fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _isAcceptingTask ? null : _acceptTask,
                                  icon: _isAcceptingTask 
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                      )
                                    : const Icon(Icons.check_circle, size: 20),
                                  label: Text(_isAcceptingTask ? 'Kabul Ediliyor...' : 'Kabul Et', style: const TextStyle(fontSize: 14)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isAcceptingTask ? Colors.grey : Colors.green,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text('Bu görevi aldınız!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedTask = null;
                                  _taskAccepted = false;
                                });
                              },
                              icon: const Icon(Icons.casino, size: 20),
                              label: const Text('Yeni Seç', style: TextStyle(fontSize: 14)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
      ),
    );
  }
} 