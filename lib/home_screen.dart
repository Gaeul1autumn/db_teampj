// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'recipe_list_page.dart';

// -----------------------------------------------------------------
// 📌 1. 모델 클래스 수정
// -----------------------------------------------------------------
class Ingredient {
  final int id;
  final String name;
  final bool isOwned; // 'is_owned' 속성 추가

  Ingredient({
    required this.id,
    required this.name,
    required this.isOwned,
  });

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
      // DB의 'is_owned' 컬럼이 0 또는 1 (INTEGER)이라고 가정
      isOwned: map['is_owned'] == 1,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Ingredient> _allIngredients = [];
  Map<int, bool> _checkedStatus = {}; // { 1: true, 2: false, 3: true }
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // -----------------------------------------------------------------
  // 📌 2. 데이터 로딩 로직 수정 (더 간단해짐)
  // -----------------------------------------------------------------
  Future<void> _loadData() async {
    // 1. 'ingredients' 테이블에서 모든 재료 목록 가져오기 (is_owned 포함)
    final ingredientsData = await _dbHelper.getUserIngredients();

    setState(() {
      _allIngredients = ingredientsData.map((map) => Ingredient.fromMap(map)).toList();

      // 2. _checkedStatus 맵을 DB의 'is_owned' 값으로 직접 초기화
      _checkedStatus = {
        for (var ingredient in _allIngredients)
          ingredient.id: ingredient.isOwned // DB의 isOwned 값을 그대로 사용
      };
      
      _isLoading = false; // 로딩 완료
    });
  }

  // -----------------------------------------------------------------
  // 📌 3. 저장 로직 수정
  // -----------------------------------------------------------------
  Future<void> _saveSelection() async {
    try {
      // 1. DB에 현재 상태 저장
      await _dbHelper.updateOwnedStatus(_checkedStatus);

      if (!mounted) return; // (중요) 비동기 작업 후 context 유효성 검사

      // 2. 저장 성공 알림
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('보유 재료가 저장되었습니다.'),
          backgroundColor: Colors.green,
        ),
      );
      
      // 3. (신규) 레시피 목록 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const RecipeListPage(),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('저장 중 오류 발생: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '보유 재료 체크',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(207, 255, 136, 62)
            )
          )
          : ListView.builder(
              itemCount: _allIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _allIngredients[index];
                
                return CheckboxListTile(
                  title: Text(ingredient.name),
                  // _checkedStatus 맵의 현재 상태를 UI에 반영
                  value: _checkedStatus[ingredient.id] ?? false,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    // 체크박스 클릭 시 _checkedStatus 맵의 상태만 변경
                    setState(() {
                      _checkedStatus[ingredient.id] = newValue;
                    });
                  },
                  activeColor: Colors.blue,
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSelection, // '완료' 누르면 3번 함수 호출
        icon: const Icon(Icons.check),
        label: const Text('완료'),
        backgroundColor: Color.fromARGB(207, 255, 136, 62),
        foregroundColor: Colors.black,
      ),
    );
    // ---------------------------------------------------------
  }
}