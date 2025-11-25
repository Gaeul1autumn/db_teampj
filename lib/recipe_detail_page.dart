import 'package:flutter/material.dart';
import 'database_helper.dart';

// -------------------------------------------------
// 1. 모델 클래스 정의 (DB 데이터를 Dart 객체로 변환)
// -------------------------------------------------
class RecipeDetail {
  final int id;
  final String name;
  final String? description;
  final String? imagePath;
  final int? cookingTime;
  final int? difficulty;

  RecipeDetail({
    required this.id,
    required this.name,
    this.description,
    this.imagePath,
    this.cookingTime,
    this.difficulty,
  });

  factory RecipeDetail.fromMap(Map<String, dynamic> map) {
    return RecipeDetail(
      id: map['recipe_id'],
      name: map['recipe_name'],
      description: map['description'],
      imagePath: map['image_path'],
      cookingTime: map['cooking_time_minutes'],
      difficulty: map['difficulty'],
    );
  }
}

class RequiredIngredient {
  final int id;
  final String name;
  final bool isOwned;
  final String? quantity;

  RequiredIngredient({
    required this.id,
    required this.name,
    required this.isOwned,
    this.quantity,
  });

  factory RequiredIngredient.fromMap(Map<String, dynamic> map) {
    return RequiredIngredient(
      id: map['ingredient_id'],
      name: map['name'],
      isOwned: map['is_owned'] == 1, // 0/1을 bool로
      quantity: map['quantity'],
    );
  }
}

class RecipeStep {
  final int stepNumber;
  final String description;
  final String? imagePath;

  RecipeStep({required this.stepNumber, required this.description, this.imagePath,});

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep(
      stepNumber: map['step_number'],
      description: map['step_description'],
      imagePath: map['image_path'],
    );
  }
}
// -------------------------------------------------

class RecipeDetailPage extends StatefulWidget {
  final int recipeId; // 목록 페이지에서 전달받은 ID
  final bool showIngredientCheck;

  const RecipeDetailPage({
    super.key, 
    required this.recipeId,
    this.showIngredientCheck = true,
  });

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 3종류의 데이터를 담을 상태 변수
  RecipeDetail? _recipeDetail;
  List<RequiredIngredient> _ingredients = [];
  List<RecipeStep> _steps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipeData();
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

  // 함수를 호출하여 3종류의 데이터를 모두 로드
  Future<void> _loadRecipeData() async {
    try {
      final data = await _dbHelper.getRecipeDetails(widget.recipeId);

      if (mounted) {
        setState(() {
          _recipeDetail = RecipeDetail.fromMap(data['details']);
          
          _ingredients = (data['ingredients'] as List)
              .map((map) => RequiredIngredient.fromMap(map))
              .toList();
              
          _steps = (data['steps'] as List)
              .map((map) => RecipeStep.fromMap(map))
              .toList();
              
          _isLoading = false;
        });
      }
    } catch (e) {
      print("레시피 상세 로딩 오류: $e");
      if (mounted) {
        setState(() { _isLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("레시피를 불러오는 데 실패했습니다: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 로딩이 끝나면 레시피 이름을 제목으로
        title: Text(
          _recipeDetail?.name ?? '로딩 중...',
          style: TextStyle(
              fontWeight: FontWeight.bold,
          )
        ),
      ),
      body: _isLoading
          ? const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(207, 255, 136, 62),
            )
          )
          : _buildRecipeContent(), // 스크롤 가능한 본문
    );
  }

  // 스크롤 가능한 본문 위젯
  Widget _buildRecipeContent() {
    if (_recipeDetail == null) {
      return const Center(child: Text('레시피 데이터를 불러오지 못했습니다.'));
    }
    
    // SingleChildScrollView + Column = 스크롤 가능한 페이지
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
         // 1. (선택) 이미지 섹션
          if (_recipeDetail!.imagePath != null)
            Image.network(
              _recipeDetail!.imagePath!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          
          // 2. 기본 정보 섹션
          _buildInfoSection(),
          
          const Divider(height: 32),

          // 3. 필요한 재료 섹션
          _buildIngredientsSection(),
          
          const Divider(height: 32),

          // 4. 요리 순서 섹션
          _buildStepsSection(),
          
          const SizedBox(height: 40), // 하단 여백
        ],
      ),
    );
  }

  // 2. 기본 정보 (제목, 설명, 요리 시간 등)
  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _recipeDetail!.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (_recipeDetail!.cookingTime != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, size: 18, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    '${_recipeDetail!.cookingTime}분',
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),

                  const SizedBox(width: 12),
                  Row(
                    children: List.generate(5, (index) {
                      final starCount = _recipeDetail!.difficulty!;
                      return Icon(
                        index < starCount ? Icons.star : Icons.star_border,
                        size: 16,
                        color: Colors.grey,
                      );
                    }),
                  ),

                  const SizedBox(width: 4),
                  // 난이도 텍스트
                  Text(
                    _difficultyToString(_recipeDetail!.difficulty!),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          if (_recipeDetail!.description != null)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Text(
                _recipeDetail!.description!,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  // 3. 필요한 재료 (보유 여부 체크)
  Widget _buildIngredientsSection() {
    final List<RequiredIngredient> missingIngredients = 
        _ingredients.where((ing) => !ing.isOwned).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '필요한 재료',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          // ListView.builder 대신 Column 사용 (스크롤 중첩 방지)
          Column(
            children: _ingredients.map((ing) {

              if (!widget.showIngredientCheck) {
                return ListTile(
                  leading: const Icon(Icons.fiber_manual_record, size: 10, color: Colors.grey),
                  title: Text(ing.name),
                  trailing: Text(ing.quantity ?? ''),
                  visualDensity: VisualDensity.compact, // 간격 좁게
                );
              }

              return ListTile(
                // 보유 여부에 따라 아이콘 변경
                leading: Icon(
                  ing.isOwned ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: ing.isOwned ? Colors.green : Colors.grey,
                ),
                title: Text(
                  ing.name,
                  style: TextStyle(
                    decoration: ing.isOwned 
                        ? TextDecoration.lineThrough // 보유 시 취소선
                        : TextDecoration.none,
                    color: ing.isOwned ? Colors.grey[600] : Colors.black,
                  ),
                ),
                trailing: Text(ing.quantity ?? ''), // 수량
              );
            }).toList(),
          ),
          
          // 📌 (핵심 기능) 부족한 재료가 있을 경우, 장바구니 버튼 표시
          if (widget.showIngredientCheck && missingIngredients.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: Center(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add_shopping_cart),
                  label: Text('부족한 재료 ${missingIngredients.length}개 장바구니 추가'),
                  onPressed: () async {
                    try {
                      // 1단계에서 만든 DB 헬퍼 함수 호출
                      await _dbHelper.addItemsToShoppingList(missingIngredients);
                      
                      // 성공 알림
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('부족한 재료를 장바구니에 담았습니다! (중복 제외)'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      // 실패 알림
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('장바구니 추가 중 오류: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 4. 요리 순서
  Widget _buildStepsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '요리 순서',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          Column(
            children: _steps.map((step) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. 스텝 번호
                    CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      foregroundColor: Colors.blue,
                      radius: 16,
                      child: Text('${step.stepNumber}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 16),

                    // 2. 이미지 + 설명
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ------------------------------------------------
                          // 📌 [수정] URL 이미지가 있을 때만 Image.network 표시
                          // ------------------------------------------------
                          if (step.imagePath != null && step.imagePath!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                step.imagePath!, // DB에 저장된 URL (예: https://site.com/img.jpg)
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                
                                // (1) 로딩 중에 보여줄 위젯 (선택 사항)
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    color: Colors.grey[100],
                                    child: Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress.expectedTotalBytes != null
                                            ? loadingProgress.cumulativeBytesLoaded /
                                                loadingProgress.expectedTotalBytes!
                                            : null,
                                      ),
                                    ),
                                  );
                                },

                                // (2) URL이 잘못되었거나 로드 실패 시 보여줄 위젯
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text("이미지를 불러올 수 없음", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 12), // 이미지와 텍스트 사이 간격
                          ],
                          // ------------------------------------------------

                          // 3. 설명 텍스트
                          Text(
                            step.description,
                            style: const TextStyle(fontSize: 16, height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}