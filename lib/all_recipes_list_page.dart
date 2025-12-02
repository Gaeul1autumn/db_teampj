import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'recipe_detail_page.dart'; // 상세 페이지로 이동하기 위해 임포트

// (Recipe 모델은 recipe_list_page.dart의 것과 동일한 구조)
class Recipe {
  final int id;
  final String name;

  Recipe({required this.id, required this.name});

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['recipe_id'], 
      name: map['recipe_name'],
    );
  }
}

class Tag {
  final int id;
  final String name;
  const Tag({required this.id, required this.name});
}

class AllRecipesListPage extends StatefulWidget {
  const AllRecipesListPage({super.key});

  @override
  State<AllRecipesListPage> createState() => _AllRecipesListPageState();
}

class _AllRecipesListPageState extends State<AllRecipesListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  // ------------------------------------------------------
  // 📌 태그 필터 관련 변수들
  // ------------------------------------------------------
  bool _tagFilteringDisabled = false; // 기본값: 필터 적용 (필요하면 true로 시작)
  
  Map<String, bool> _categoryExpanded = {
    "요리 종류": false,
    "난이도": false,
    "조리기구": false,
  };

  Set<int> _selectedTagIds = {};

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
      const Tag(id: 24, name: "냄비")
    ],
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1번 파일에서 만든 'getFullRecipeList' 호출
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final data = await _dbHelper.getFullRecipeList(
        tagIds: _tagFilteringDisabled ? null : _selectedTagIds.toList(),
        isTagDisabled: _tagFilteringDisabled,
      );
      if (mounted) {
        setState(() {
          _recipes = data.map((map) => Recipe.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      print("전체 레시피 로딩 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 탭 페이지에 종속되므로 자체 Scaffold/AppBar가 필요
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '전체 레시피',
          style: TextStyle(
              fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Column(
        children: [
          // -----------------------------------------------
          // 📌 [필터 영역] 태그 스위치 및 상세 설정
          // -----------------------------------------------
          Container(
            color: Colors.white,
            child: Column(
              children: [
                // 1. 태그 사용 안함 스위치
                SwitchListTile(
                  title: const Text(
                    "태그 필터 사용 안함 (전체 보기)",
                    style: TextStyle(fontWeight: FontWeight.bold,),
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
                  onChanged: (value) {
                    setState(() {
                      _tagFilteringDisabled = value;
                    });
                    // 📌 스위치를 끄고 켤 때마다 즉시 리스트 새로고침
                    _loadData();
                  },
                ),
                
                // 2. 태그 상세 설정 (활성화 시에만 보임)
                if (!_tagFilteringDisabled)
                  ExpansionTile(
                    title: const Text("태그 상세 선택"),
                    subtitle: Text(
                      "선택된 태그: ${_selectedTagIds.length}개",
                      style: TextStyle(color: Colors.blue[700], fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                    children: [
                      ..._buildTagCategories(),
                      const SizedBox(height: 10),
                    ],
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1),

          // -----------------------------------------------
          // 📌 [리스트 영역]
          // -----------------------------------------------
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    if (_recipes.isEmpty) {
      return const Center(
        child: Text(
          '레시피가 없습니다.',
          style: TextStyle(
            fontSize: 18.0,
          ),
        )
      );
    }

    // 당겨서 새로고침
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return ListTile(
            title: Text(recipe.name),
            leading: const Icon(Icons.restaurant_menu_outlined),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 📌 상세 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RecipeDetailPage(
                    recipeId: recipe.id,
                    showIngredientCheck: false,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
  // ------------------------------------------------------
  // 📌 태그 카테고리 빌더 (실시간 갱신 적용)
  // ------------------------------------------------------
  List<Widget> _buildTagCategories() {
    return _tagCategories.keys.map((category) {
      final tags = _tagCategories[category]!;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            visualDensity: VisualDensity.compact,
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
                      // 📌 [핵심] 칩을 선택/해제 할 때마다 _loadData() 호출
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
                        // 즉시 새로고침
                        _loadData();
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

