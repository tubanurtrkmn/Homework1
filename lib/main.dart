import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ColumnRowTasarmi(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ColumnRowTasarmi extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: Text('Column & Row Tasarımı',
        style: TextStyle(color: Colors.white),),
        centerTitle: true,

      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              color: Colors.purple[200],
              child: Center(
                child: Text(
                  'Üst Başlık',
                  style: TextStyle(fontSize: 18,color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBox('Box 1', Colors.orange),
                _buildBox('Box 2', Colors.green),
                _buildBox('Box 3', Colors.blue),
              ],
            ),
            SizedBox(height: 16),
            _buildLargeBox('Alt Box A', Colors.teal),
            SizedBox(height: 16),
            _buildLargeBox('Alt Box B', Colors.redAccent),
          ],
        ),
      ),
    );
  }

  Widget _buildBox(String title, Color color) {
    return Expanded(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildLargeBox(String title, Color color) {
    return Container(
      width: double.infinity,
      height: 150,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
      ),
    );
  }
}
