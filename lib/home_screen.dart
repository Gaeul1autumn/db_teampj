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
      id: map['Id'],
      name: map['name'],
      // DB의 'is_owned' 컬럼이 0 또는 1 (INTEGER)이라고 가정
      isOwned: map['is_owned'] == 1,
    );
  }
}

//태그 클래스
class Tag {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
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

  // ------------------------------------------------------
  // 📌 3. 태그 필터 관련 변수 추가
  // ------------------------------------------------------
  bool _tagFilteringDisabled = false; // 태그 사용 안함 여부
  bool _isFilterExpanded = false;     // 필터 섹션 펼침 여부 (UI 깔끔하게 하려고 추가)

  // 카테고리별 펼침 상태
  Map<String, bool> _categoryExpanded = {
    "요리 종류": false,
    "난이도": false,
    "조리기구": false,
  };

  // 선택된 태그 ID 저장소
  Set<int> _selectedTagIds = {};

  // 태그 데이터 정의
  final Map<String, List<Tag>> _tagCategories = {
    "요리 종류": [
      const Tag(id: 1, name: "한식"), const Tag(id: 2, name: "양식"),
      const Tag(id: 3, name: "중식"), const Tag(id: 4, name: "일식"),
      const Tag(id: 5, name: "디저트"),
    ],
    "난이도": [
      const Tag(id: 10, name: "매우 쉬움"),
      const Tag(id: 11, name: "쉬움"), const Tag(id: 12, name: "보통"),
      const Tag(id: 13, name: "어려움"),const Tag(id: 14, name: "매우 어려움")
    ],
    "조리기구": [
      const Tag(id: 20, name: "프라이팬"), const Tag(id: 21, name: "전자레인지"),
      const Tag(id: 22, name: "에어프라이어"), const Tag(id: 23, name: "오븐"),
      const Tag(id: 24, name: "냄비"),
    ],
  };

  @override
  void initState() {
    super.initState();
    _initPage();
  }

  List<String> _getSelectedTagNames() {
    List<String> names = [];
    
    // 모든 카테고리를 순회하며 선택된 태그를 찾음
    _tagCategories.forEach((category, tags) {
      for (var tag in tags) {
        if (_selectedTagIds.contains(tag.id)) {
          names.add(tag.name);
        }
      }
    });
    
    return names;
  }

  Future<void> _initPage() async {
    // 1. 먼저 DB의 모든 체크박스 상태를 0(false)으로 초기화
    //테스트 때문에 주석
    print("is_owned 전부 초기화 완료");
    await _dbHelper.resetAllIngredientStatus();

    // 2. 초기화가 끝난 후 데이터를 불러와 화면에 그리기
    // (이때 불러오면 모두 false 상태로 불러와집니다)
    if (mounted) {
      await _loadData();
    }
  }

  // -----------------------------------------------------------------
  // 📌 2. 데이터 로딩 로직 수정 
  // -----------------------------------------------------------------
  Future<void> _loadData() async {
    // 1. 'ingredients' 테이블에서 모든 재료 목록 가져오기 (is_owned 포함)
    print("🚩 [1] _loadData 시작");
    final ingredientsData = await _dbHelper.getUserIngredients();
    print("🚩 [2] 데이터 가져오기 성공: ${ingredientsData.length}개 발견");
    print("🚩 [2-1] 데이터 내용 확인: $ingredientsData"); // 내용물 확인

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
      await _dbHelper.updateOwnedStatus(_checkedStatus);

      if (!mounted) return;
      List<String> selectedNames = _getSelectedTagNames();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('설정이 적용되었습니다.'), duration: Duration(seconds: 1)),
      );

      // recipelistpage로 이동하면서 "태그 필터 정보" 전달
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecipeListPage(
            // 📌 여기서 수집한 태그 정보를 직접 넣어줍니다.
            // 태그 사용 안함이면 null을 보내고, 아니면 리스트를 보냅니다.
            tagIds: _tagFilteringDisabled ? null : _selectedTagIds.toList(),
            isTagDisabled: _tagFilteringDisabled,
            tagNames: _tagFilteringDisabled ? null : selectedNames,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '재료 및 태그 선택',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color.fromARGB(207, 255, 136, 62),
      ),
      backgroundColor: Color.fromARGB(255, 251, 249, 244),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(
            color: Color.fromARGB(207, 255, 136, 62),
          ))
          : Column(
              children: [
                // -----------------------------------------------
                // 📌 5. 상단 태그 필터 영역 (접었다 폈다 가능하게)
                // -----------------------------------------------
                Container(
                  color: Colors.white,
                  child: SwitchListTile(
                    title: const Text(
                      "태그 필터 사용 안함",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      _tagFilteringDisabled
                          ? "태그를 사용하지 않고 레시피를 검색합니다."
                          : "활성화시 태그없이 레시피를 검색합니다.",
                      style: _tagFilteringDisabled
                          ?  TextStyle(fontSize: 12, color: const Color.fromARGB(255, 250, 126, 2))
                          :  TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                      
                    value: _tagFilteringDisabled,
                    activeColor: Colors.orange, // 강조색 (선택 사항)
                    inactiveThumbColor: const Color.fromARGB(255, 123, 123, 123), // 원하는 보라색으로 직접 지정
                    inactiveTrackColor: const Color.fromARGB(255, 123, 123, 123).withOpacity(0.5),
                    onChanged: (value) {
                      setState(() {
                        _tagFilteringDisabled = value;
                        // (옵션) 태그를 끄면 펼쳐진 카테고리들도 다 접고 싶다면 아래 주석 해제
                        // if (value) _categoryExpanded.updateAll((key, val) => false);
                      });
                    },
                  ),
                ),
                
                const Divider(height: 1),

                if (!_tagFilteringDisabled) 
                  Container(
                    color: Colors.white,
                    // 애니메이션 효과와 함께 나타나도록 AnimatedCrossFade 등을 쓸 수도 있지만
                    // 간단하게 조건부 렌더링(if)으로 처리했습니다.
                    child: ExpansionTile(
                      title: Text(
                        "태그 상세 선택", 
                        style: TextStyle(fontSize: 15, color: Colors.grey[800]),
                      ),
                      subtitle: Text(
                        "선택된 태그: ${_selectedTagIds.length}개",
                        style: TextStyle(color: Colors.blue[700], fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      initiallyExpanded: false, // 기본적으로는 접어둠
                      children: [
                        // 기존에 만든 태그 카테고리 빌더 호출
                        ..._buildTagCategories(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                
                if (!_tagFilteringDisabled)
                  const Divider(height: 1),

                // -----------------------------------------------
                // 📌 6. 하단 재료 리스트 영역 (Expanded로 남은 공간 채움)
                // -----------------------------------------------
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80), // FAB 공간 확보
                    itemCount: _allIngredients.length,
                    itemBuilder: (context, index) {
                      final ingredient = _allIngredients[index];
                      return CheckboxListTile(
                        title: Text(ingredient.name),
                        value: _checkedStatus[ingredient.id] ?? false,
                        onChanged: (bool? newValue) {
                          if (newValue == null) return;
                          setState(() {
                            _checkedStatus[ingredient.id] = newValue;
                          });
                        },
                        activeColor: Color.fromARGB(207, 255, 136, 62),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSelection,
        icon: const Icon(Icons.check),
        label: const Text('완료 (레시피 보기)'),
        backgroundColor: Color.fromARGB(207, 255, 136, 62),
        foregroundColor: Colors.black,
        heroTag: "home_complete_btn",
      ),
    );
  }

  // ------------------------------------------------------
  // 📌 7. 태그 카테고리 빌더 (제공해주신 코드 병합)
  // ------------------------------------------------------
  List<Widget> _buildTagCategories() {
    return _tagCategories.keys.map((category) {
      final tags = _tagCategories[category]!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            visualDensity: VisualDensity.compact, // 간격 좁게
            title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            trailing: Icon(
              _categoryExpanded[category] == true ? Icons.expand_less : Icons.expand_more,
              size: 20,
            ),
            onTap: () {
              setState(() {
                _categoryExpanded[category] = !(_categoryExpanded[category] ?? false);
              });
            },
          ),
          
          if (_categoryExpanded[category] == true)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: tags.map((tag) {
                  final isSelected = _selectedTagIds.contains(tag.id);
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(tag.name),
                      selected: isSelected,
                      // 1️⃣ 선택되었을 때 배경색
                      selectedColor: Colors.orange.shade100, 
                      // 2️⃣ 선택 안 되었을 때 배경색 (기본값은 회색)
                      backgroundColor: Colors.grey[200],
                      onSelected: (bool selected) {
                        setState(() {
                          if (selected) {
                            // 1. 현재 카테고리에 있는 다른 태그들을 모두 선택 해제!
                            for (var t in tags) {
                              _selectedTagIds.remove(t.id);
                            }
                            // 2. 방금 클릭한 태그만 추가
                            _selectedTagIds.add(tag.id);
                          } else {
                            // 이미 선택된 걸 다시 누르면 해제 (선택 안 함 상태 가능)
                            _selectedTagIds.remove(tag.id);
                          }
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      );
    }).toList();
  }
}