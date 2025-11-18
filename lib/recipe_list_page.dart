// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'database_helper.dart'; 
import 'missing_ingredients_page.dart';
import 'recipe_detail_page.dart';
import 'missing_ingredients_sorted_page.dart';

// 1. DB 쿼리 결과를 담을 Recipe 모델
// (쿼리 결과 컬럼명이 'recipe_id', 'recipe_name'이라고 가정)
class Recipe {
  final int id;
  final String name;

  Recipe({required this.id, required this.name});

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['recipe_id'], // 1번 파일의 쿼리 결과 컬럼명
      name: map['recipe_name'], // 1번 파일의 쿼리 결과 컬럼명
    );
  }
}

class RecipeListPage extends StatefulWidget {
  const RecipeListPage({super.key});

  @override
  State<RecipeListPage> createState() => _RecipeListPageState();
}

class _RecipeListPageState extends State<RecipeListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  // 1번 파일의 getAvailableRecipes() 함수를 호출
  Future<void> _loadRecipes() async {
    try {
      // 1번 파일에서 사용자가 쿼리를 작성할 함수 호출
      final recipeData = await _dbHelper.getAvailableRecipes();

      if (mounted) {
        setState(() {
          _recipes = recipeData.map((map) => Recipe.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("레시피 로딩 오류: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("레시피를 불러오는 데 실패했습니다: $e")),
        );
      }
    }
  }

  // 리스트를 새로고침하는 함수 (Pull-to-Refresh)
  Future<void> _refreshList() async {
    // _loadRecipes를 다시 호출하여 데이터를 새로고침
    await _loadRecipes();
  }

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('추천 레시피 목록'),
          backgroundColor: Colors.white,
          elevation: 1,
          // -------------------------------------------------------
          // 📌 (신규) 우측 상단 아이콘 버튼 2개 추가
          // -------------------------------------------------------
          actions: [
            IconButton(
              tooltip: '부족한 재료 1개',
              icon: const Icon(Icons.filter_1), // 숫자 '1' 아이콘
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 3번에서 만들 페이지로 '1'을 전달
                    builder: (context) => const MissingIngredientsPage(
                      missingCount: 1,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              tooltip: '부족한 재료 2개',
              icon: const Icon(Icons.filter_2), // 숫자 '2' 아이콘
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    // 3번에서 만들 페이지로 '2'를 전달
                    builder: (context) => const MissingIngredientsPage(
                      missingCount: 2,
                    ),
                  ),
                );
              },
            ),
            IconButton(
            tooltip: '부족한 재료 3개 이상',
            icon: const Icon(Icons.filter_3), // '3+' 아이콘
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  // 3번에서 만들 새 페이지로 이동
                  builder: (context) => const MissingIngredientsSortedPage(),
                ),
              );
            },
          ), 
            const SizedBox(width: 8), // 우측 살짝 여백
          ],
          // -------------------------------------------------------
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildRecipeList(),
      );
    }

  // 레시피 목록 또는 '결과 없음' 메시지를 보여주는 위젯
  Widget _buildRecipeList() {
    if (_recipes.isEmpty) {
      // 결과가 없을 때
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.no_food_outlined, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '만들 수 있는 레시피가 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _refreshList, 
              child: const Text('새로고침'),
            )
          ],
        ),
      );
    }

    // 결과가 있을 때 (RefreshIndicator로 감싸서 당겨서 새로고침)
    return RefreshIndicator(
      onRefresh: _refreshList,
      child: ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, index) {
          final recipe = _recipes[index];
          return ListTile(
            title: Text(recipe.name),
            leading: const Icon(Icons.restaurant_menu), // 레시피 아이콘
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              //레시피 상세 페이지로 이동
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