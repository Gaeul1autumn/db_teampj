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

class AllRecipesListPage extends StatefulWidget {
  const AllRecipesListPage({super.key});

  @override
  State<AllRecipesListPage> createState() => _AllRecipesListPageState();
}

class _AllRecipesListPageState extends State<AllRecipesListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Recipe> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // 1번 파일에서 만든 'getFullRecipeList' 호출
  Future<void> _loadData() async {
    setState(() { _isLoading = true; });
    try {
      final data = await _dbHelper.getFullRecipeList();
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
      body: _isLoading
          ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(207, 255, 136, 62),
            )
          )
          : _buildListView(),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadData,
        tooltip: '새로고침',
        backgroundColor: Color.fromARGB(207, 255, 136, 62),
        child: const Icon(Icons.refresh),
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