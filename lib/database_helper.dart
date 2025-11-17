// lib/database_helper.dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // DB 파일 이름을 'my_data.db'로 가정합니다.
  // 1단계에서 사용한 파일 이름과 동일해야 합니다.
  static const String _databaseName = "my_data.db";
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
  // 여기에 사용자가 직접 쿼리 함수를 만드시면 됩니다.
  // (사용자 요청: 쿼리 부분은 직접 작성)
  // -----------------------------------------------------------------


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
  // 📌 2. 'user_ingredients' 테이블에서 현재 보유 재료 ID 목록 가져오기
  // (테이블명 'user_ingredients', 컬럼명 'ingredient_id'로 가정)
  // -----------------------------------------------------------------
  Future<List<Map<String, dynamic>>> getOwnedIngredientIds() async {
    Database db = await instance.database;
    return await db.query('user_ingredients', columns: ['ingredient_id']);
  }

  // -----------------------------------------------------------------
  // 📌 3. 'user_ingredients' 테이블 전체 업데이트 (완료 버튼 클릭시)
  // -----------------------------------------------------------------
  Future<void> updateOwnedIngredients(List<int> selectedIds) async {
    Database db = await instance.database;
    
    // 트랜잭션을 사용해 여러 작업을 한번에 처리 (안정성)
    await db.transaction((txn) async {
      // 1. 기존 보유 재료 목록 전체 삭제
      await txn.delete('user_ingredients');
      
      // 2. 새로 선택된 재료들만 일괄 삽입 (Batch)
      Batch batch = txn.batch();
      for (int id in selectedIds) {
        // 'ingredient_id' 컬럼에 ID 저장
        batch.insert('user_ingredients', {'ingredient_id': id});
      }
      
      // 3. 일괄 작업 실행
      await batch.commit();
    });
    print("보유 재료 업데이트 완료!");
  }


  
}