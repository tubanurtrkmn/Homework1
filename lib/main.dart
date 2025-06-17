import 'package:flutter/material.dart';

void main() {
  runApp(KisilikAnketiApp());
}

class KisilikAnketiApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kişilik Anketi',
      home: KisilikAnketi(),
    );
  }
}

class KisilikAnketi extends StatefulWidget {
  @override
  _KisilikAnketiState createState() => _KisilikAnketiState();
}

class _KisilikAnketiState extends State<KisilikAnketi> {
  String adSoyad = '';
  String? secilenCinsiyet;
  bool resitMi = false;
  bool sigaraKullaniyorMu = false;
  double sigaraSayisi = 0;
  bool bilgilerGoster = false;

  final List<String> cinsiyetListesi = ['Kadın', 'Erkek', 'Diğer'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kişilik Anketi'),
        backgroundColor: Colors.deepOrange,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Adınız ve Soyadınız'),
              onChanged: (value) {
                setState(() {
                  adSoyad = value;
                });
              },
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              hint: Text('Cinsiyetinizi Seçiniz'),
              value: secilenCinsiyet,
              items: cinsiyetListesi.map((String cinsiyet) {
                return DropdownMenuItem<String>(
                  value: cinsiyet,
                  child: Text(cinsiyet),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  secilenCinsiyet = value;
                });
              },
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Checkbox(
                  value: resitMi,
                  onChanged: (value) {
                    setState(() {
                      resitMi = value!;
                    });
                  },
                ),
                Text('Reşit misiniz?'),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Switch(
                  value: sigaraKullaniyorMu,
                  onChanged: (value) {
                    setState(() {
                      sigaraKullaniyorMu = value;
                    });
                  },
                  activeColor: Colors.red,
                ),
                Text('Sigara kullanıyor musunuz?'),
              ],
            ),
            if (sigaraKullaniyorMu)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Günde kaç tane sigara içiyorsunuz?'),
                  Slider(
                    value: sigaraSayisi,
                    min: 0,
                    max: 40,
                    divisions: 40,
                    label: sigaraSayisi.round().toString(),
                    onChanged: (value) {
                      setState(() {
                        sigaraSayisi = value;
                      });
                    },
                  ),
                ],
              ),
            SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    bilgilerGoster = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                ),
                child: Text('Bilgileri gönder'),
              ),
            ),
            if (bilgilerGoster)
              Container(
                margin: EdgeInsets.only(top: 24),
                padding: EdgeInsets.all(16),
                color: Colors.orange.shade100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Ad Soyad: $adSoyad"),
                    Text("Cinsiyet: ${secilenCinsiyet ?? 'Seçilmedi'}"),
                    Text("Reşit mi?: ${resitMi ? 'Evet' : 'Hayır'}"),
                    Text("Sigara kullanıyor mu?: ${sigaraKullaniyorMu ? 'Evet' : 'Hayır'}"),
                    if (sigaraKullaniyorMu)
                      Text("Günlük Sigara Sayısı: ${sigaraSayisi.round()}"),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
