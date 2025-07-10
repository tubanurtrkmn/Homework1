import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DonationItem {
  final String name;
  final String description;
  final IconData icon;
  final int requiredPoints;
  final Color color;
  final String impact;

  DonationItem({
    required this.name,
    required this.description,
    required this.icon,
    required this.requiredPoints,
    required this.color,
    required this.impact,
  });
}

class DonationPage extends StatefulWidget {
  const DonationPage({Key? key}) : super(key: key);

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final List<DonationItem> donationItems = [
    DonationItem(
      name: 'Fidan Dikimi',
      description: '1 adet ağaç fidanı dikimi',
      icon: Icons.eco,
      requiredPoints: 1000,
      color: Colors.green,
      impact: '🌱 1 ağaç dikildi',
    ),
    DonationItem(
      name: 'Eğitim Desteği',
      description: 'Bir çocuğun eğitim malzemesi',
      icon: Icons.school,
      requiredPoints: 2000,
      color: Colors.orange,
      impact: '📚 1 çocuk için eğitim',
    ),
    DonationItem(
      name: 'Hayvan Desteği',
      description: 'Sokak hayvanları için mama',
      icon: Icons.pets,
      requiredPoints: 800,
      color: Colors.brown,
      impact: '🐕 10 hayvan',
    ),
    DonationItem(
      name: 'Temizlik Projesi',
      description: 'Çevre temizlik projesi',
      icon: Icons.cleaning_services,
      requiredPoints: 1500,
      color: Colors.teal,
      impact: '🧹 1 park temizlendi',
    ),
    DonationItem(
      name: 'Sağlık Desteği',
      description: 'Sağlık malzemesi bağışı',
      icon: Icons.medical_services,
      requiredPoints: 3000,
      color: Colors.red,
      impact: '🏥 1 aile için sağlık',
    ),
    DonationItem(
      name: 'Kütüphane Projesi',
      description: 'Köy okullarına kitap bağışı',
      icon: Icons.library_books,
      requiredPoints: 2500,
      color: Colors.purple,
      impact: '📖 50 kitap bağışlandı',
    ),
  ];

  bool isDonating = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Giriş yapmadınız!')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bağış Yap'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Kullanıcı verisi bulunamadı.'));
          }
          
          final userData = snapshot.data!.data() as Map<String, dynamic>;
          final userPoints = userData['totalPoints'] ?? 0;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık ve puan bilgisi
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.volunteer_activism, color: Colors.green, size: 32),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Puanlarınızı Bağışa Çevirin',
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green[200]!),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.star, color: Colors.amber, size: 24),
                              const SizedBox(width: 8),
                              Text(
                                'Mevcut Puanınız: $userPoints',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bağış seçenekleri
                const Text(
                  'Bağış Seçenekleri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: donationItems.length,
                  itemBuilder: (context, index) {
                    final item = donationItems[index];
                    final canAfford = userPoints >= item.requiredPoints;
                    
                    return Card(
                      elevation: canAfford ? 4 : 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: canAfford ? item.color : Colors.grey[300]!,
                          width: canAfford ? 2 : 1,
                        ),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: canAfford ? () => _showDonationDialog(item, userPoints) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: canAfford ? item.color.withOpacity(0.1) : Colors.grey[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  item.icon,
                                  size: 32,
                                  color: canAfford ? item.color : Colors.grey[400],
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: canAfford ? item.color : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.impact,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: canAfford ? item.color.withOpacity(0.8) : Colors.grey[500],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: canAfford ? item.color : Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${item.requiredPoints} puan',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: canAfford ? Colors.white : Colors.grey[600],
                                  ),
                                ),
                              ),
                              if (!canAfford)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${item.requiredPoints - userPoints} puan eksik',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 24),
                
                // Bilgi kartı
                Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Nasıl Çalışır?',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[700],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• Puanlarınızı gerçek dünya projelerine bağışlayabilirsiniz\n'
                          '• Her bağış, gerçek bir etki yaratır\n'
                          '• Bağış geçmişiniz profilinizde görünür\n'
                          '• Daha fazla görev tamamlayarak daha fazla bağış yapabilirsiniz',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.blue[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showDonationDialog(DonationItem item, int userPoints) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(
                  color: item.color,
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
            Text(item.description),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    item.impact,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: item.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Maliyet: ${item.requiredPoints} puan',
                    style: TextStyle(
                      fontSize: 14,
                      color: item.color.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Bu bağışı yapmak istediğinizden emin misiniz?',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: isDonating ? null : () => _makeDonation(item),
            style: ElevatedButton.styleFrom(
              backgroundColor: item.color,
              foregroundColor: Colors.white,
            ),
            child: isDonating
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Bağış Yap'),
          ),
        ],
      ),
    );
  }

  Future<void> _makeDonation(DonationItem item) async {
    setState(() {
      isDonating = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Kullanıcının puanını güncelle
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'totalPoints': FieldValue.increment(-item.requiredPoints),
      });

      // Bağış geçmişini kaydet
      await FirebaseFirestore.instance.collection('donations').add({
        'userId': user.uid,
        'donationName': item.name,
        'donationDescription': item.description,
        'pointsSpent': item.requiredPoints,
        'impact': item.impact,
        'donatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop(); // Dialog'u kapat
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} bağışınız başarıyla yapıldı! ${item.impact}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
        
        // Sayfayı yenile
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bağış yapılırken hata oluştu: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isDonating = false;
      });
    }
  }
} 