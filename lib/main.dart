// lib/main.dart
import 'package:flutter/material.dart';
import 'main_tabs_page.dart';

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
        scaffoldBackgroundColor: const Color.fromARGB(244, 251, 249, 244),
        primarySwatch: Colors.blue,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white, // 배경색을 흰색으로 설정
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color.fromARGB(207, 255, 136, 62), // 모든 AppBar의 기본 배경색을 흰색으로 설정
          elevation: 0,                  // 모든 AppBar의 그림자 제거
          surfaceTintColor: Colors.transparent, // 모든 AppBar의 M3 틴트 제거
        ),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      // 3번에서 만들 HomeScreen을 앱의 메인 화면으로 지정
      home: const MainTabsPage(), 
    );
  }
}