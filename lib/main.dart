import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    int sayi = 42;
    String metin = "Merhaba";
    double oran = 3.14;
    bool durum = true;
    dynamic degisken = "Değişebilir";
    String karakter = 'A';


    int camelCaseSayi = 10;
    int snake_case_sayi = 20;
    int PascalCaseSayi = 30;


    String ad = "Tubanur";
    String soyad = "Türkmen";
    int yas = 22;
    bool resitMi = true;

    print("int: $sayi");
    print("String: $metin");
    print("double: $oran");
    print("bool: $durum");
    print("dynamic: $degisken");
    print("char (String): $karakter");

    print("Camel Case: $camelCaseSayi");
    print("Snake Case: $snake_case_sayi");
    print("Pascal Case: $PascalCaseSayi");

    print("Ad: $ad, Soyad: $soyad, Yaş: $yas, Reşit mi: $resitMi");

    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text("Konsolu kontrol et!"),
        ),
      ),
    );
  }
}
