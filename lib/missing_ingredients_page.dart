// lib/missing_ingredients_page.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'recipe_detail_page.dart';

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

class MissingIngredientsPage extends StatefulWidget {
  // 이 페이지가 1개 부족 리스트인지, 2개 부족 리스트인지 결정
  final int missingCount; 
  
  const MissingIngredientsPage({
    super.key, 
    required this.missingCount,
  });

  @override
  State<MissingIngredientsPage> createState() => _MissingIngredientsPageState();
}

class _MissingIngredientsPageState extends State<MissingIngredientsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Recipe> _recipes = [];
  bool _isLoading = true;
  late String _appBarTitle; // 앱바 제목

  @override
  void initState() {
    super.initState();
    // 제목 설정
    _appBarTitle = "부족한 재료 ${widget.missingCount}개";
    _loadData();
  }

  // 'missingCount'에 따라 다른 DB 함수를 호출
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _recipes = []; // 새로고침 시 리스트 초기화
    });

    List<Map<String, dynamic>> recipeData;
    try {
      // -------------------------------------------------
      // 📌 파라미터 값에 따라 분기
      // -------------------------------------------------
      if (widget.missingCount == 1) {
        recipeData = await _dbHelper.getRecipesMissingOne();
      } else if (widget.missingCount == 2) {
        recipeData = await _dbHelper.getRecipesMissingTwo();
      } else {
        // 혹시 모를 예외 처리
        recipeData = [];
      }
      // -------------------------------------------------

      if (mounted) {
        setState(() {
          _recipes = recipeData.map((map) => Recipe.fromMap(map)).toList();
          _isLoading = false;
        });
      }

    } catch (e) {
      print("레시피 로딩 오류: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("데이터 로딩 오류: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_appBarTitle), // 동적으로 설정된 제목
      ),
      body: _isLoading
          ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(207, 255, 136, 62),
            )
          )
          : _buildRecipeList(),
    );
  }

  // (recipe_list_page.dart의 _buildRecipeList와 거의 동일)
  Widget _buildRecipeList() {
    if (_recipes.isEmpty) {
      // 결과가 없을 때
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '해당 레시피가 없습니다.',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _loadData, // 새로고침
              child: const Text('새로고침'),
            )
          ],
        ),
      );
    }

    // 결과가 있을 때 (Pull-to-refresh)
    return RefreshIndicator(
      onRefresh: _loadData, // 당겨서 새로고침
      child: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return ListTile(
            title: Text(recipe.name),
            leading: const Icon(Icons.restaurant_menu),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              // 레시피 상세 페이지로 이동
              print("선택된 레시피 ID: ${recipe.id}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  //RecipeDetailPage로 ID 전달
                  builder: (context) => RecipeDetailPage(recipeId: recipe.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}