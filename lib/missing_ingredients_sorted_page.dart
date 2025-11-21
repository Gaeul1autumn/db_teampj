// lib/missing_ingredients_sorted_page.dart
import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'recipe_detail_page.dart'; // 상세 페이지로 이동

// 📌 1. (신규) 'missing_count'를 포함하는 새 모델
// 1번 파일의 쿼리 결과와 컬럼명('recipe_id', 'recipe_name', 'missing_count')이
// 일치해야 합니다.
class RecipeWithMissingCount {
  final int id;
  final String name;
  final int missingCount; // 쿼리에서 이 값을 받아야 함

  RecipeWithMissingCount({
    required this.id,
    required this.name,
    required this.missingCount,
  });

  factory RecipeWithMissingCount.fromMap(Map<String, dynamic> map) {
    return RecipeWithMissingCount(
      id: map['recipe_id'],
      name: map['recipe_name'],
      missingCount: map['missing_count'], // 쿼리 결과에 이 컬럼이 있어야 함
    );
  }
}

class MissingIngredientsSortedPage extends StatefulWidget {
  const MissingIngredientsSortedPage({super.key});

  @override
  State<MissingIngredientsSortedPage> createState() => _MissingIngredientsSortedPageState();
}

class _MissingIngredientsSortedPageState extends State<MissingIngredientsSortedPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<RecipeWithMissingCount> _recipes = []; // 📌 새 모델 사용
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1번 파일의 'getRecipesMissingThreeOrMoreSorted' 함수 호출
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _recipes = []; // 새로고침 시 리스트 초기화
    });

    try {
      // 1번 파일에서 만든 새 함수 호출
      final data = await _dbHelper.getRecipesMissingThreeOrMoreSorted();

      if (mounted) {
        setState(() {
          _recipes = data.map((map) => RecipeWithMissingCount.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print("정렬된 레시피 로딩 오류: $e");
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
        title: const Text('부족한 재료 (3개 이상)'),
      ),
      body: _isLoading
          ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(207, 255, 136, 62),
            )
          )
          : _buildListView(),
    );
  }

  Widget _buildListView() {
    if (_recipes.isEmpty) {
      // 결과가 없을 때
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '해당 레시피가 없습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
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
            leading: const Icon(Icons.restaurant_menu_outlined),
            
            // -------------------------------------------------
            // 📌 (신규) 부족한 개수를 Chip으로 표시 (정렬 확인용)
            // -------------------------------------------------
            trailing: Chip(
              label: Text('${recipe.missingCount}개 부족'),
              backgroundColor: Colors.red[50], // 연한 빨간색 배경
              labelStyle: TextStyle(color: Colors.red[700]), // 진한 빨간색 글씨
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              visualDensity: VisualDensity.compact, // 칩 크기를 좀 더 작게
            ),
            // -------------------------------------------------
            
            onTap: () {
              // 📌 상세 페이지로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
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