import 'package:flutter/material.dart';
// QUAN TRỌNG: Import file chứa màn hình Rubik
// Nếu file rubik_scene.dart của bạn nằm trong thư mục lib/screens/ thì để dòng dưới:
import 'screens/rubik_scene.dart';
// Nếu file rubik_scene.dart nằm ngay cạnh main.dart thì dùng: import 'rubik_scene.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rubik 3D Flutter',
      debugShowCheckedModeBanner: false, // Tắt chữ DEBUG ở góc phải
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.deepPurple,
        useMaterial3: true,
      ),
      // THAY ĐỔI Ở ĐÂY: Trỏ về màn hình RubikScene thay vì MyHomePage
      home: RubikScene(),
    );
  }
}
