import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const FaceIdApp());
}

class FaceIdApp extends StatelessWidget {
  const FaceIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face ID - MediaPipe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
