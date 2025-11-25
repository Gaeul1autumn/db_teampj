// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'database_helper.dart'; 
import 'recipe_detail_page.dart';

// 1. DB 쿼리 결과를 담을 Recipe 모델
// (쿼리 결과 컬럼명이 'recipe_id', 'recipe_name'이라고 가정)
class Recipe {
  final int id;
  final String name;
  final int missingCount;
  final int? cookingTime;
  final int? difficulty;

  Recipe({
    required this.id,
    required this.name,
    required this.missingCount,
    this.cookingTime,
    this.difficulty,
  });

  factory Recipe.fromMap(Map<String, dynamic> map) {
    return Recipe(
      id: map['recipe_id'],
      name: map['recipe_name'],
      missingCount: map['missing_count'],
      cookingTime: map['cooking_time_minutes'],
      difficulty: map['difficulty'],
    );
  }
}

class RecipeListPage extends StatefulWidget {
  final List<int>? tagIds;
  final bool? isTagDisabled;

  final List<String>? tagNames;

  const RecipeListPage({
    super.key, 
    this.tagIds, 
    this.isTagDisabled,
    this.tagNames,
  });

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

  // 1번 파일의 getIntegratedRecipes() 함수를 호출
  Future<void> _loadRecipes() async {
    try {
      // 1번 파일에서 사용자가 쿼리를 작성할 함수 호출
      // 📌 DB 헬퍼 함수 호출 시 필터 정보 전달
      final recipeData = await _dbHelper.getIntegratedRecipeList(
        tagIds: widget.tagIds,
        isTagDisabled: widget.isTagDisabled,
      );

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

  String _difficultyToString(int difficulty) {
  switch (difficulty) {
    case 1:
      return "매우 쉬움";
    case 2:
      return "쉬움";
    case 3:
      return "보통";
    case 4:
      return "어려움";
    case 5:
      return "매우 어려움";
    default:
      return "error";
  }
}

  @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            '추천 레시피 목록',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            )
          ),
          backgroundColor: Color.fromARGB(207, 255, 136, 62),
        ),
        body: Column(
          children: [
            // -------------------------------------------------------
            // 📌 [신규] 선택된 태그 목록 표시 영역
            // -------------------------------------------------------
            if (widget.isTagDisabled != true && widget.tagNames != null && widget.tagNames!.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[100], // 연한 회색 배경
                  border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "적용된 태그",
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal, // 가로 스크롤
                      child: Row(
                        children: widget.tagNames!.map((name) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: Chip(
                              label: Text(
                                name,
                                style: const TextStyle(fontSize: 12, color: Colors.white),
                              ),
                              backgroundColor: const Color.fromARGB(255, 129, 128, 128), // 칩 색상
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              side: BorderSide.none, // 테두리 없음
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            
            // -------------------------------------------------------
            // 📌 기존 리스트 영역 (Expanded로 감싸야 함)
            // -------------------------------------------------------
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color.fromARGB(207, 255, 136, 62),
                      ),
                    )
                  : _buildUnifiedRecipeList(),
            ),
          ],
        ),
      );
    }

  // 레시피 목록 또는 '결과 없음' 메시지를 보여주는 위젯
  Widget _buildUnifiedRecipeList() {
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
          Color badgeColor;
          String badgeText;

          if (recipe.missingCount == 0) {
            badgeColor = Colors.green;
            badgeText = "조리 가능";
          } else if (recipe.missingCount <= 2) {
            badgeColor = Colors.orange;
            badgeText = "${recipe.missingCount}개 부족";
          } else {
            badgeColor = const Color.fromARGB(255, 255, 0, 0);
            badgeText = "${recipe.missingCount}개 부족";
          }
          
          return ListTile(
            title: Text(recipe.name),
            subtitle: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. 요리 시간 (데이터가 있을 때만)
                    if (recipe.cookingTime != null && recipe.cookingTime! > 0) ...[
                      const Icon(Icons.access_time, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        "${recipe.cookingTime}분",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      // 시간과 난이도 사이 구분선 (둘 다 있을 때만 표시)
                      if (recipe.difficulty != null)
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6),
                          child: Text("|", style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ),
                    ],

                    // 2. 난이도 (데이터가 있을 때만)
                    if (recipe.difficulty != null) ...[
                     Row(
                      children: List.generate(5, (index) {
                        final starCount = recipe.difficulty!;
                        return Icon(
                          index < starCount ? Icons.star : Icons.star_border,
                          size: 14,
                          color: Colors.grey,
                        );
                      }),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _difficultyToString(recipe.difficulty!),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    ],
                  ],
                ),
            leading: const Icon(Icons.restaurant_menu), // 레시피 아이콘
            trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: badgeColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            ),
            onTap: () {
              //레시피 상세 페이지로 이동
              print("선택된 레시피 ID: ${recipe.id}");
              Navigator.push(
                context,
                MaterialPageRoute(
                  //RecipeDetailPage로 ID 전달
                  builder: (context) => RecipeDetailPage(
                    recipeId: recipe.id,
                    showIngredientCheck: true,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}