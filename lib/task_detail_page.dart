import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'services/task_service.dart';
import 'home_page.dart';

class TaskDetailPage extends StatefulWidget {
  final Map<String, dynamic> taskData;
  final dynamic userTaskData;

  const TaskDetailPage({Key? key, required this.taskData, required this.userTaskData}) : super(key: key);

  @override
  State<TaskDetailPage> createState() => _TaskDetailPageState();
}

class _TaskDetailPageState extends State<TaskDetailPage> {
  int currentPoints = 0;
  int maxPoints = 0;
  int minPoints = 0;
  DateTime? assignedAt;
  DateTime? endDate;
  int durationDays = 0;
  bool isLoading = true;
  bool isCompletingTask = false; // Görev tamamlama durumu

  @override
  void initState() {
    super.initState();
    print('TaskDetailPage initState - userTaskData: ${widget.userTaskData}');
    print('TaskDetailPage initState - userTaskData.id: ${widget.userTaskData.id}');
    print('TaskDetailPage initState - userTaskData.data(): ${widget.userTaskData.data()}');
    _loadTaskData();
  }

  Future<void> _loadTaskData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Önce görev puanını güncelle
      await TaskService().updateTaskPoints(widget.userTaskData.id);
      
      // Görev verilerini yükle
      if (widget.userTaskData.data()?['assignedAt'] != null) {
        assignedAt = widget.userTaskData.data()?['assignedAt'].toDate();
      }
      
      maxPoints = widget.userTaskData.data()?['maxPoints'] ?? widget.taskData['maxPoints'];
      minPoints = widget.userTaskData.data()?['minPoints'] ?? widget.taskData['minPoints'];
      durationDays = widget.userTaskData.data()?['durationDays'] ?? widget.taskData['durationDays'];
      
      if (assignedAt != null) {
        endDate = assignedAt!.add(Duration(days: durationDays));
        
        // Güncellenmiş puanı al
        currentPoints = widget.userTaskData.data()?['currentPoints'] ?? widget.userTaskData.data()?['maxPoints'] ?? widget.taskData['maxPoints'];
        
        // Aktif görev ise puanı hesapla
        if (widget.userTaskData.data()?['status'] == 'active' && assignedAt != null) {
          currentPoints = TaskService().calculateCurrentPoints(
            assignedAt: assignedAt!,
            maxPoints: maxPoints,
            minPoints: minPoints,
            durationDays: durationDays,
          );
        }
      } else {
        currentPoints = maxPoints;
      }
    } catch (e) {
      print('Error loading task data: $e');
      currentPoints = maxPoints;
    }

    setState(() {
      isLoading = false;
    });
  }

  String _getPointsInfo() {
    if (assignedAt == null || endDate == null) return '';
    
    final now = DateTime.now();
    final elapsedDays = now.difference(assignedAt!).inDays;
    final remainingDays = durationDays - elapsedDays;
    
    if (remainingDays <= 0) {
      return 'Görev süresi dolmuş! Minimum puan: $minPoints';
    }
    
    if (elapsedDays == 0) {
      return 'Görev yeni başladı! Maksimum puan: $maxPoints';
    }
    
    final pointReduction = maxPoints - currentPoints;
    return 'Geçen süre: $elapsedDays gün\nKalan süre: $remainingDays gün\nPuan azalması: $pointReduction puan';
  }

  Color _getPointsColor() {
    if (currentPoints == maxPoints) return Colors.green;
    if (currentPoints > (maxPoints + minPoints) / 2) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.userTaskData.data()?['status'] ?? 'unknown';
    DateTime? completedAt;
    if (widget.userTaskData.data()?['completedAt'] != null) {
      completedAt = widget.userTaskData.data()?['completedAt']?.toDate();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Görev Detayı')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Görev başlığı ve açıklaması
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.taskData['title'] ?? '', 
                               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(widget.taskData['description'] ?? '', 
                               style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Tarih bilgileri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📅 Tarih Bilgileri', 
                               style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                          const SizedBox(height: 8),
                          Text('Başlangıç: ${assignedAt != null ? DateFormat('dd.MM.yyyy HH:mm').format(assignedAt!) : '-'}'),
                          Text('Bitiş: ${endDate != null ? DateFormat('dd.MM.yyyy HH:mm').format(endDate!) : '-'}'),
                          if (completedAt != null) 
                            Text('Tamamlandı: ${DateFormat('dd.MM.yyyy HH:mm').format(completedAt)}'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Puan bilgileri
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                          Row(
                            children: [
                              Icon(Icons.star, color: _getPointsColor(), size: 24),
                              const SizedBox(width: 8),
                              Text('Puan Bilgileri', 
                                   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _getPointsColor())),
                            ],
                          ),
            const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Mevcut Puan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text('$currentPoints', 
                                         style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _getPointsColor())),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Maksimum Puan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text('$maxPoints', style: TextStyle(fontSize: 16, color: Colors.green[700])),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Minimum Puan', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    Text('$minPoints', style: TextStyle(fontSize: 16, color: Colors.red[700])),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
                  
                  // Bilgilendirme paneli
                  if (status == 'active' && assignedAt != null)
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text('Bilgilendirme', 
                                     style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue[700])),
                              ],
                            ),
            const SizedBox(height: 8),
                            Text(_getPointsInfo(), style: TextStyle(fontSize: 13, color: Colors.blue[800])),
            const SizedBox(height: 8),
                            Text('💡 İpucu: Görevleri erken tamamlayarak maksimum puanı kazanabilirsiniz!', 
                                 style: TextStyle(fontSize: 12, color: Colors.blue[600], fontStyle: FontStyle.italic)),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Durum bilgisi
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: status == 'active' ? Colors.green[100] : 
                             status == 'completed' ? Colors.blue[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Durum: ${status == 'active' ? 'Aktif' : status == 'completed' ? 'Tamamlandı' : 'İptal Edildi'}',
                      style: TextStyle(
                        color: status == 'active' ? Colors.green[700] : 
                               status == 'completed' ? Colors.blue[700] : Colors.red[700],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
            const SizedBox(height: 24),
                  
                  // Aksiyon butonları
            if (status == 'active')
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                            icon: isCompletingTask 
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.check),
                            label: Text(isCompletingTask ? 'Tamamlanıyor...' : 'Tamamla'),
                      style: ElevatedButton.styleFrom(
                              backgroundColor: isCompletingTask ? Colors.grey : Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                            onPressed: isCompletingTask ? null : () async {
                              // Eğer zaten görev tamamlanıyorsa, işlemi engelle
                              if (isCompletingTask) {
                                print('Görev tamamlama zaten devam ediyor');
                                return;
                              }
                              
                              try {
                                setState(() {
                                  isCompletingTask = true;
                                });
                                
                                print('Görev tamamlama başladı');
                                print('userTaskData: ${widget.userTaskData}');
                                print('userTaskData.id: ${widget.userTaskData.id}');
                                print('userTaskData.data(): ${widget.userTaskData.data()}');
                                
                                // userTaskData bir DocumentSnapshot olmalı
                                if (widget.userTaskData is! DocumentSnapshot) {
                                  throw Exception('Geçersiz görev verisi');
                                }
                                
                                final userTaskId = widget.userTaskData.id;
                                print('Görev ID: $userTaskId');
                                
                                // ID'nin geçerli olduğunu kontrol et
                                if (userTaskId.isEmpty) {
                                  throw Exception('Geçersiz görev ID');
                                }
                                
                                // Loading göster
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                                
                        await TaskService().updateUserTaskStatus(
                                  userTaskId: userTaskId,
                          status: 'completed',
                        );
                                
                                print('Görev tamamlama tamamlandı');
                                
                                // Loading'i kapat
                                Navigator.of(context).pop();
                                
                                // Başarı mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Görev başarıyla tamamlandı!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                                
                                // Ana sayfaya yönlendir ve sayfayı yenile
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (context) => const HomePage()),
                                    (route) => false,
                                  );
                                }
                              } catch (e) {
                                print('Görev tamamlama hatası: $e');
                                
                                // Loading'i kapat
                                Navigator.of(context).pop();
                                
                                // Hata mesajı göster
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } finally {
                                setState(() {
                                  isCompletingTask = false;
                                });
                              }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Vazgeç'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        await TaskService().updateUserTaskStatus(
                                userTaskId: widget.userTaskData.id,
                          status: 'cancelled',
                        );
                        Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
                  
                  // Alt boşluk
                  const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
} 