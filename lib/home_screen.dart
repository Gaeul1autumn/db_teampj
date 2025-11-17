import 'package:flutter/material.dart';
import 'database_helper.dart'; 

// 1. DB 데이터를 Dart 객체로 다루기 위한 모델 클래스
// (DB 테이블 컬럼명 'id', 'name'을 가정)
class Ingredient {
  final int id;
  final String name;

  Ingredient({required this.id, required this.name});

  factory Ingredient.fromMap(Map<String, dynamic> map) {
    return Ingredient(
      id: map['id'],
      name: map['name'],
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // DB 헬퍼 인스턴스
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 상태 변수들
  List<Ingredient> _allIngredients = []; // 1. DB에서 가져온 모든 재료 목록
  Map<int, bool> _checkedStatus = {}; // 2. 각 재료(ID)별 체크 상태
  bool _isLoading = true; // 3. 데이터 로딩 중인지 여부

  @override
  void initState() {
    super.initState();
    // 화면이 시작될 때 DB에서 데이터를 불러옵니다.
    _loadData();
  }

  // DB에서 (1)전체 재료와 (2)보유 재료를 불러와 상태를 초기화하는 함수
  Future<void> _loadData() async {
    // 1. 'ingredients' 테이블에서 모든 재료 목록 가져오기
    final ingredientsData = await _dbHelper.getAllIngredients();
    
    // 2. 'user_ingredients' 테이블에서 현재 보유한 재료 ID 목록 가져오기
    final ownedIdsData = await _dbHelper.getOwnedIngredientIds();
    
    // Set<int>로 변환하여 검색 속도를 빠르게 함
    final ownedIdSet = ownedIdsData.map((map) => map['ingredient_id'] as int).toSet();

    // 가져온 데이터를 상태 변수에 반영
    setState(() {
      _allIngredients = ingredientsData.map((map) => Ingredient.fromMap(map)).toList();

      // '전체 재료'를 기준으로 '보유 재료'를 체크하여 _checkedStatus 맵 생성
      _checkedStatus = {
        for (var ingredient in _allIngredients)
          ingredient.id: ownedIdSet.contains(ingredient.id) // 보유 중이면 true, 아니면 false
      };
      
      _isLoading = false; // 로딩 완료
    });
  }

  // '완료' 버튼을 눌렀을 때 DB에 저장하는 함수
  Future<void> _saveSelection() async {
    // _checkedStatus 맵에서 현재 true(체크됨)인 항목들의 ID만 리스트로 추출
    final List<int> selectedIds = _checkedStatus.entries
        .where((entry) => entry.value == true) // value가 true인 (체크된) 항목만 필터링
        .map((entry) => entry.key) // key(재료 ID)만 추출
        .toList();

    try {
      // 1번 파일에서 만든 함수를 호출하여 DB에 저장
      await _dbHelper.updateOwnedIngredients(selectedIds);

      // 저장 성공 시 사용자에게 알림 (SnackBar)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('보유 재료가 저장되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // 저장 실패 시
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('저장 중 오류 발생: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('보유 재료 체크'),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      backgroundColor: Colors.grey[50],
      // 로딩 중일 경우 로딩 스피너를, 로딩이 끝나면 리스트를 보여줌
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _allIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = _allIngredients[index];
                
                // 체크박스와 타이틀이 결합된 ListTile
                return CheckboxListTile(
                  title: Text(ingredient.name),
                  // _checkedStatus 맵에서 현재 재료 ID의 체크 상태를 가져옴
                  value: _checkedStatus[ingredient.id] ?? false,
                  onChanged: (bool? newValue) {
                    if (newValue == null) return;
                    // 체크박스 클릭 시 _checkedStatus 맵의 상태를 업데이트
                    setState(() {
                      _checkedStatus[ingredient.id] = newValue;
                    });
                  },
                  activeColor: Colors.blue,
                );
              },
            ),
      // '완료' 버튼 (FloatingActionButton)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSelection, // 6번 함수 호출
        icon: const Icon(Icons.check),
        label: const Text('완료'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}