import 'package:flutter/material.dart';
import 'database_helper.dart';

// 1. DB 쿼리 결과를 담을 모델
// (shopping_list 테이블의 컬럼명 'id', 'name' 가정)
class ShoppingItem {
  final int id; // 'shopping_list'의 PK (ingredient_id 아님)
  final String name;

  ShoppingItem({required this.id, required this.name});

  factory ShoppingItem.fromMap(Map<String, dynamic> map) {
    return ShoppingItem(
      id: map['id'],
      name: map['name'],
    );
  }
}

class ShoppingListPage extends StatefulWidget {
  const ShoppingListPage({super.key});

  @override
  State<ShoppingListPage> createState() => _ShoppingListPageState();
}

class _ShoppingListPageState extends State<ShoppingListPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<ShoppingItem> _shoppingList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShoppingList();
  }

  // 1번 파일에서 만든 'getShoppingList' 호출
  Future<void> _loadShoppingList() async {
    setState(() { _isLoading = true; }); // 로딩 시작
    try {
      final data = await _dbHelper.getShoppingList();
      if (mounted) {
        setState(() {
          _shoppingList = data.map((map) => ShoppingItem.fromMap(map)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
      print("장바구니 로딩 오류: $e");
    }
  }

  // 1번 파일에서 만든 'removeFromShoppingList' 호출 (삭제 기능)
  Future<void> _deleteItem(int id) async {
    try {
      await _dbHelper.removeFromShoppingList(id);
      // DB에서 삭제 성공 시, 화면(state)에서도 해당 항목 제거
      setState(() {
        _shoppingList.removeWhere((item) => item.id == id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('장바구니에서 삭제되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("장바구니 삭제 오류: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // 📌 이 페이지는 'main_tabs_page'에 포함될 것이므로
    // 그 페이지의 AppBar를 사용합니다.
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '장바구니',
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
          : _buildShoppingListView(),
      // 📌 새로고침 버튼 (Pull-to-refresh 대신)
      // (다른 탭에 갔다가 돌아올 때 자동으로 새로고침 되도록 구현할 수도 있음)
      floatingActionButton: FloatingActionButton(
        onPressed: _loadShoppingList,
        tooltip: '새로고침',
        backgroundColor: Color.fromARGB(207, 255, 136, 62),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  // 장바구니 리스트 UI
  Widget _buildShoppingListView() {
    if (_shoppingList.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '장바구니가 비어있습니다.',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // 목록이 있을 때
    return ListView.builder(
      itemCount: _shoppingList.length,
      itemBuilder: (context, index) {
        final item = _shoppingList[index];
        
        // 📌 밀어서 삭제하는 기능 (Dismissible)
        return Dismissible(
          key: Key(item.id.toString()), // 각 항목을 구분하는 고유 키
          direction: DismissDirection.endToStart, // 오른쪽 -> 왼쪽으로 밀기
          // 밀었을 때 실행할 동작 (DB 삭제)
          onDismissed: (direction) {
            _deleteItem(item.id);
          },
          // 밀었을 때 배경 (휴지통 아이콘)
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          child: ListTile(
            title: Text(item.name),
            leading: const Icon(Icons.label_important_outline),
          ),
        );
      },
    );
  }
}