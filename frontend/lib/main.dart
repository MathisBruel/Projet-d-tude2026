import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgriSense Test',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Test Page'),
        ),
        body: const Center(
          child: Text('Just a basic test page'),
        ),
      ),
    );
  }
}
