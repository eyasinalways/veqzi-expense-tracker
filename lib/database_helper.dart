import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "ExpenseTracker.db";
  static const _databaseVersion = 2; // ভার্সন ১ থেকে ২ করা হলো

  static const table = 'transactions';

  static const columnId = '_id';
  static const columnTitle = 'title';
  static const columnAmount = 'amount';
  static const columnDate = 'date';
  static const columnCategory = 'category';
  static const columnType = 'type';
  static const columnNote = 'note'; // নতুন কলাম

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade, // ডেটাবেস আপডেটের ফাংশন
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $table (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnTitle TEXT NOT NULL,
            $columnAmount REAL NOT NULL,
            $columnDate TEXT NOT NULL,
            $columnCategory TEXT NOT NULL,
            $columnType TEXT NOT NULL,
            $columnNote TEXT
          )
          ''');
  }

  // পুরনো ডেটাবেসে নতুন কলাম যুক্ত করার ম্যাজিক!
  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute("ALTER TABLE $table ADD COLUMN $columnNote TEXT DEFAULT ''");
    }
  }

  Future<int> insert(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  Future<List<Map<String, dynamic>>> queryAllRows() async {
    Database db = await instance.database;
    return await db.query(table, orderBy: "$columnDate DESC");
  }

  Future<List<Map<String, dynamic>>> queryRowsByMonth(int year, int month) async {
    Database db = await instance.database;
    String monthStr = month.toString().padLeft(2, '0');
    String yearStr = year.toString().padLeft(4, '0');
    String pattern = "$yearStr-$monthStr-%";
    return await db.query(
      table,
      where: "$columnDate LIKE ?",
      whereArgs: [pattern],
      orderBy: "$columnDate DESC",
    );
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }
  static Future<void> resetDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}