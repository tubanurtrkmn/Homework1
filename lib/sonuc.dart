import 'package:flutter/material.dart';

class SonucSayfasi extends StatelessWidget {
  final String adSoyad;
  final String cinsiyet;
  final bool resitMi;
  final bool sigaraKullaniyorMu;
  final int sigaraSayisi;

  const SonucSayfasi({
    Key? key,
    required this.adSoyad,
    required this.cinsiyet,
    required this.resitMi,
    required this.sigaraKullaniyorMu,
    required this.sigaraSayisi,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sonuçlar'),
        backgroundColor: Colors.deepOrange,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.orange.shade100,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ad Soyad: $adSoyad', style: TextStyle(fontSize: 18)),
                Text('Cinsiyet: $cinsiyet', style: TextStyle(fontSize: 18)),
                Text('Reşit mi?: ${resitMi ? 'Evet' : 'Hayır'}', style: TextStyle(fontSize: 18)),
                Text('Sigara Kullanıyor mu?: ${sigaraKullaniyorMu ? 'Evet' : 'Hayır'}', style: TextStyle(fontSize: 18)),
                if (sigaraKullaniyorMu)
                  Text('Günlük Sigara Sayısı: $sigaraSayisi', style: TextStyle(fontSize: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}