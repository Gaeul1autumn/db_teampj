import 'package:flutter/material.dart';
import 'home_screen.dart'; // 기존 홈 화면
import 'shopping_list_page.dart'; // 2번에서 만든 장바구니 화면
import 'all_recipes_list_page.dart';

class MainTabsPage extends StatefulWidget {
  const MainTabsPage({super.key});

  @override
  State<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends State<MainTabsPage> {
  int _selectedIndex = 0; // 현재 선택된 탭 인덱스

  // 1. 하단 탭으로 보여줄 페이지 목록
  // 📌 IndexedStack: 탭이 전환되어도 각 페이지의 상태를 보존 (스크롤 위치 등)
  static final List<Widget> _widgetOptions = <Widget>[
    const HomeScreen(),        // 탭 0: 기존 재료 관리 화면
    const AllRecipesListPage(), // 탭1: 모든 레시피 출력 화면
    const ShoppingListPage(),  // 탭 2: 새로 만든 장바구니 화면
  ];

  // 2. 탭을 클릭했을 때 호출될 함수
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. 본문: IndexedStack을 사용해 선택된 탭의 페이지만 보여줌
      // (HomeScreen과 ShoppingListPage 각각의 Scaffold/AppBar가 사용됨)
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      
      // 4. 하단 네비게이션 바 (탭 바)
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.kitchen),
            label: '보유 재료',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: '전체 레시피',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart),
            label: '장바구니',
          ),
        ],
        currentIndex: _selectedIndex, // 현재 활성화된 탭
        selectedItemColor: Color.fromARGB(207, 255, 136, 62), // 활성화된 탭 색상
        onTap: _onItemTapped, // 탭 클릭 시 2번 함수 호출

        // type: BottomNavigationBarType.fixed, FIXME: 탭 계속 활성화 원하면 주석 제거 지금은 선택한 탭만 활성화
      ),
    );
  }
}