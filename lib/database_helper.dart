// lib/database_helper.dart
// ignore_for_file: avoid_print

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'recipe_detail_page.dart';

class DatabaseHelper {
  // DB 파일 이름을 'my_data.db'로 가정합니다.
  // 1단계에서 사용한 파일 이름과 동일해야 합니다.
  static const String _databaseName = "app.db";
  static Database? _database;

  // 싱글톤 패턴: 앱 전체에서 이 인스턴스 하나만 사용
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // 데이터베이스 인스턴스에 접근
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // 데이터베이스 초기화 (복사 및 열기)
  Future<Database> _initDb() async {
    // 1. 데이터베이스 경로 가져오기
    String dbPath = await getDatabasesPath();
    String path = join(dbPath, _databaseName);

    // 2. 해당 경로에 DB 파일이 존재하는지 확인
    bool exists = await databaseExists(path);

    if (!exists) {
      // 3. 파일이 존재하지 않으면, assets에서 복사
      print("Creating new copy from asset...");

      // (필요시) 부모 디렉토리 생성
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Assets에서 DB 파일 읽어오기
      ByteData data = await rootBundle.load(join("assets", _databaseName));
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // 파일 쓰기
      await File(path).writeAsBytes(bytes, flush: true);
      
      print("Database copied.");
    } else {
      print("Opening existing database.");
    }

    // 4. 데이터베이스 열기
    return await openDatabase(path);
  }


  // -----------------------------------------------------------------
  // 📌 1. 'ingredients' 테이블에서 모든 재료 가져오기
  // (테이블명 'ingredients', 컬럼명 'id', 'name'으로 가정)
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAllIngredients() async {
    Database db = await instance.database;
    // 'name' 컬럼 기준으로 가나다순 정렬
    return await db.query('ingredients', orderBy: 'name ASC');
  }



  // -----------------------------------------------------------------
  // 📌 3. 'user_ingredients' 테이블 전체 업데이트 (완료 버튼 클릭시)
  // -----------------------------------------------------------------
  Future<void> updateOwnedStatus(Map<int, bool> statusMap) async {
      Database db = await instance.database;
      
      // Batch: 여러 개의 업데이트 작업을 하나로 묶어 실행 (매우 효율적)
      Batch batch = db.batch();

      // statusMap의 모든 항목(ID: 체크상태)을 순회
      statusMap.forEach((id, isOwned) {
        // isOwned가 true이면 1, false이면 0을 저장
        int ownedValue = isOwned ? 1 : 0; 
        
        batch.update(
          'ingredients',        // 테이블
          {'is_owned': ownedValue}, // 업데이트할 값
          where: 'id = ?',        // 조건
          whereArgs: [id],        // 조건 값
        );
      });

      // 묶어둔 모든 업데이트 작업을 한 번에 실행
      await batch.commit();
      print("재료 'is_owned' 상태 일괄 업데이트 완료!");
    }



  // -----------------------------------------------------------------
  // 📌 4. (신규) 만들 수 있는 레시피 목록 가져오기
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getAvailableRecipes() async {
    Database db = await instance.database;

    // FIXME: 쿼리작성 필수
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성] 
    // ⬇️ 여기에 ingredients 테이블(is_owned=1)과 
    // ⬇️ 다른 테이블을 조인하는 쿼리를 작성하세요.
    // ---------------------------------------------------------
    
    // 예시: 쿼리 결과를 'recipe_id'와 'recipe_name'으로 반환한다고 가정
    final String myCustomQuery = """
      SELECT 
        r.id as recipe_id, 
        r.name as recipe_name
      FROM recipes r
      WHERE 
        -- (여기에 '보유 재료(is_owned=1)' 기반 조인 쿼리 로직 구현)
        EXISTS (SELECT 1 FROM ... WHERE ...);
    """;
    
    // return await db.rawQuery(myCustomQuery);
    
    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    // 쿼리 작성이 완료되면 이 부분은 삭제하고, 위 return await ... 주석을 해제하세요.
    print("임시 데이터를 반환합니다. 쿼리를 작성해주세요.");
    await Future.delayed(const Duration(seconds: 1)); // 로딩 테스트용
    return [
      {'recipe_id': 101, 'recipe_name': '김치찌개 (테스트 데이터)'},
      {'recipe_id': 102, 'recipe_name': '된장찌개 (테스트 데이터)'},
    ];
  }

  Future<List<Map<String, dynamic>>> getRecipesMissingOne() async {
    Database db = await instance.database;

    //FIXME: 쿼리작성
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성]
    // ⬇️ (is_owned=1)을 기반으로, 부족한 재료가 "1개"인 레시피를 찾는
    // ⬇️ 쿼리를 작성하세요.
    // ---------------------------------------------------------
    final String myCustomQuery = """
      SELECT 
        r.id as recipe_id, 
        r.name as recipe_name
      FROM recipes r
      WHERE 
        -- (여기에 쿼리 로직 구현)
        1 = 1; -- 임시 쿼리
    """;
    // return await db.rawQuery(myCustomQuery);
    
    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    print("임시 데이터 (부족 1) 반환.");
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'recipe_id': 201, 'recipe_name': '제육볶음 (부족 1개)'},
      {'recipe_id': 202, 'recipe_name': '된장찌개 (부족 1개)'},
    ];
  }

  // -----------------------------------------------------------------
  // 📌 6. (신규) 부족한 재료가 2개인 레시피
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRecipesMissingTwo() async {
    Database db = await instance.database;

    //FIXME: 쿼리작성
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성]
    // ⬇️ (is_owned=1)을 기반으로, 부족한 재료가 "2개"인 레시피를 찾는
    // ⬇️ 쿼리를 작성하세요.
    // ---------------------------------------------------------
    final String myCustomQuery = """
      SELECT 
        r.id as recipe_id, 
        r.name as recipe_name
      FROM recipes r
      WHERE 
        -- (여기에 쿼리 로직 구현)
        1 = 2; -- 임시 쿼리 (결과 없음 테스트)
    """;
    // return await db.rawQuery(myCustomQuery);

    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    print("임시 데이터 (부족 2) 반환.");
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'recipe_id': 301, 'recipe_name': '파스타 (부족 2개)'},
    ];
  }

  // -----------------------------------------------------------------
  // 📌 7. (신규) 레시피 상세 정보 모두 가져오기 (3개 쿼리 실행)
  // -----------------------------------------------------------------
  Future<Map<String, dynamic>> getRecipeDetails(int recipeId) async {
    Database db = await instance.database;
    
    //FIXME: 쿼리 작성
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성 1: 레시피 기본 정보]
    // ---------------------------------------------------------
    // 'recipes' 테이블에서 이름, 설명, 이미지 경로 등
    final String detailsQuery = """
      SELECT 
        id as recipe_id, 
        name as recipe_name, 
        description, 
        image_path, 
        cooking_time_minutes
      FROM recipes 
      WHERE id = $recipeId
    """;
    // final List<Map<String, dynamic>> detailsData = await db.rawQuery(detailsQuery);
    // if (detailsData.isEmpty) {
    //   throw Exception("Recipe not found");
    // }
    
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성 2: 필요한 재료 목록]
    // ---------------------------------------------------------
    // 'recipe_ingredients' (중간 테이블)과 'ingredients' (메인)을 조인.
    // 'is_owned' 상태와 재료 이름, 필요 수량을 가져옵니다.
    final String ingredientsQuery = """
      SELECT 
        i.id as ingredient_id, 
        i.name, 
        i.is_owned, 
        ri.quantity  -- (예: 'recipe_ingredients' 테이블의 '수량' 컬럼)
      FROM recipe_ingredients ri
      JOIN ingredients i ON ri.ingredient_id = i.id
      WHERE ri.recipe_id = $recipeId
    """;
    // final List<Map<String, dynamic>> ingredientsData = await db.rawQuery(ingredientsQuery);

    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성 3: 요리 순서]
    // ---------------------------------------------------------
    // 'recipe_steps' 테이블에서 순서(step_number)대로 정렬
    final String stepsQuery = """
      SELECT 
        step_number, 
        step_description 
      FROM recipe_steps
      WHERE recipe_id = $recipeId
      ORDER BY step_number ASC
    """;
    // final List<Map<String, dynamic>> stepsData = await db.rawQuery(stepsQuery);


    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성 완료]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    // 쿼리 작성이 완료되면 이 'return { ... }' 블록은 삭제하고
    // 위 3개의 쿼리 결과(detailsData, ingredientsData, stepsData)를
    // 아래와 같은 맵으로 묶어 반환하세요.
    //
    // return {
    //   'details': detailsData.first,
    //   'ingredients': ingredientsData,
    //   'steps': stepsData,
    // };
    
    print("임시 레시피 상세 데이터를 반환합니다. 쿼리를 작성해주세요.");
    await Future.delayed(const Duration(milliseconds: 700));
    return {
      'details': {
        'recipe_id': recipeId,
        'recipe_name': '테스트 레시피 (ID: $recipeId)',
        'description': '보유 재료로 만들 수 있는 맛있는 레시피입니다. 쿼리를 연결해주세요.',
        'image_path': null, // 'assets/images/food.png' 또는 http://...
        'cooking_time_minutes': 30,
      },
      'ingredients': [
        {'ingredient_id': 1, 'name': '보유한 재료 (예: 양파)', 'is_owned': 1, 'quantity': '1개'},
        {'ingredient_id': 2, 'name': '부족한 재료 (예: 돼지고기)', 'is_owned': 0, 'quantity': '300g'},
        {'ingredient_id': 3, 'name': '보유한 재료 (예: 마늘)', 'is_owned': 1, 'quantity': '2쪽'},
      ],
      'steps': [
        {'step_number': 1, 'step_description': '재료를 모두 준비합니다.'},
        {'step_number': 2, 'step_description': '부족한 재료를 장바구니에 담습니다.'},
        {'step_number': 3, 'step_description': '모든 재료를 볶습니다.'},
        {'step_number': 4, 'step_description': '맛있게 먹습니다.'},
      ],
    };
  }

  // -----------------------------------------------------------------
  // 📌 8. (신규) 장바구니 목록에 추가하기
  // -----------------------------------------------------------------
  Future<void> addItemsToShoppingList(List<RequiredIngredient> missingItems) async {
    // 1. 'shopping_list' 테이블이 아래와 같다고 가정합니다.
    // (ingredient_id 컬럼은 UNIQUE여야 중복 방지가 됩니다.)
    // CREATE TABLE shopping_list (
    //   id INTEGER PRIMARY KEY AUTOINCREMENT,
    //   ingredient_id INTEGER UNIQUE,
    //   name TEXT
    // );
    
    Database db = await instance.database;
    Batch batch = db.batch();

    for (var item in missingItems) {
      batch.insert(
        'shopping_list',
        {
          'ingredient_id': item.id,
          'name': item.name,
          // (필요에 따라 item.quantity도 저장할 수 있습니다)
        },
        // 📌 (핵심) 만약 ingredient_id가 이미 테이블에 존재한다면 (UNIQUE 제약조건)
        // 이 INSERT 작업을 그냥 무시하고 넘어갑니다. (중복 추가 방지)
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    
    // 묶어둔 작업을 한 번에 실행
    await batch.commit();
    print("장바구니에 ${missingItems.length}개 항목 추가 시도 (중복 제외)");
  }

  // -----------------------------------------------------------------
  // 📌 9. (신규) 장바구니 목록 전체 가져오기
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getShoppingList() async {
    Database db = await instance.database;
    // 'shopping_list' 테이블에서 데이터를 가져옵니다. (id, ingredient_id, name)
    // 📌 'shopping_list' 테이블이 있다고 가정합니다.
    return await db.query('shopping_list', orderBy: 'name ASC');
  }

  // -----------------------------------------------------------------
  // 📌 10. (신규) 장바구니에서 항목 삭제하기 (ID 기준)
  // -----------------------------------------------------------------
  Future<void> removeFromShoppingList(int id) async {
    Database db = await instance.database;
    // 'shopping_list'의 'id' (Primary Key)를 기준으로 삭제
    await db.delete(
      'shopping_list',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // -----------------------------------------------------------------
  // 📌 11. (신규) 'recipes' 테이블의 모든 레시피 목록 가져오기
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getFullRecipeList() async {
    Database db = await instance.database;
    
    //FIXME: 쿼리 작성
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성]
    // ⬇️ 'recipes' 테이블에서 ID와 이름 등 기본 정보만 가져오는
    // ⬇️ 쿼리를 작성하세요.
    // ---------------------------------------------------------
    
    // 예시: 쿼리 결과를 'recipe_id'와 'recipe_name'으로 반환한다고 가정
    final String myCustomQuery = """
      SELECT 
        id as recipe_id, 
        name as recipe_name
      FROM recipes
      ORDER BY name ASC;
    """;
    
    // return await db.rawQuery(myCustomQuery);
    
    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    print("임시 데이터 (전체 레시피) 반환. 쿼리를 작성해주세요.");
    await Future.delayed(const Duration(milliseconds: 300));
    return [
      {'recipe_id': 101, 'recipe_name': '김치찌개 (전체)'},
      {'recipe_id': 102, 'recipe_name': '된장찌개 (전체)'},
      {'recipe_id': 201, 'recipe_name': '제육볶음 (전체)'},
      {'recipe_id': 301, 'recipe_name': '파스타 (전체)'},
    ];
  }

  // -----------------------------------------------------------------
  // 📌 12. (신규) 부족한 재료 3개 이상 (부족한 순으로 정렬)
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getRecipesMissingThreeOrMoreSorted() async {
    Database db = await instance.database;

    //FIXME: 쿼리 작성
    // ---------------------------------------------------------
    // ⬇️ [사용자 직접 작성]
    // ⬇️ (is_owned=1)을 기반으로, 부족한 재료가 "3개 이상"인 레시피를 찾는
    // ⬇️ 쿼리를 작성하세요.
    //
    // ⬇️ (중요!) 쿼리 결과에 'missing_count' (부족한 재료 개수) 컬럼이
    // ⬇️ *반드시* 포함되어야 하며, 이 값을 기준으로 정렬(ORDER BY)해야 합니다.
    // ---------------------------------------------------------
    
    final String myCustomQuery = """
      SELECT 
        r.id as recipe_id, 
        r.name as recipe_name, 
        -- (예시) 부족한 재료 개수를 계산하는 로직
        (COUNT(CASE WHEN i.is_owned = 0 THEN 1 END)) as missing_count
      FROM recipes r
      JOIN recipe_ingredients ri ON r.id = ri.recipe_id
      JOIN ingredients i ON ri.ingredient_id = i.id
      GROUP BY r.id, r.name
      HAVING missing_count >= 3
      ORDER BY 
        missing_count ASC, -- 1. 부족한 개수 적은 순
        r.name ASC;        -- 2. (같을 경우) 이름 가나다 순
    """;
    
    // return await db.rawQuery(myCustomQuery);
    
    // ---------------------------------------------------------
    // ⬆️ [사용자 직접 작성]
    // ---------------------------------------------------------

    // ⚠️ 임시 반환 값 (테스트용)
    print("임시 데이터 (부족 3+ 정렬) 반환. 쿼리를 작성해주세요.");
    await Future.delayed(const Duration(milliseconds: 500));
    return [
      {'recipe_id': 401, 'recipe_name': '갈비찜 (테스트)', 'missing_count': 3},
      {'recipe_id': 402, 'recipe_name': '잡채 (테스트)', 'missing_count': 3},
      {'recipe_id': 501, 'recipe_name': '신선로 (테스트)', 'missing_count': 5},
    ];
  }

  
}