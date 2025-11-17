// lib/main.dart
import 'package:flutter/material.dart';
import 'home_screen.dart'; // 3번에서 만들 파일

void main() {
  // DB 헬퍼가 준비되었는지 확인하기 위해 runApp 전에 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '레시피 추천 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // 3번에서 만들 HomeScreen을 앱의 메인 화면으로 지정
      home: const HomeScreen(), 
    );
  }
}