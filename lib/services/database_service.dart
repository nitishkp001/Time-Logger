import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/activity.dart';
import '../models/daily_task.dart';
import '../models/planner_item.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('time_logger.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS daily_tasks(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          category TEXT NOT NULL,
          reminderEnabled INTEGER NOT NULL DEFAULT 1
        )
      ''');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS planner_items(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT,
          startDate TEXT NOT NULL,
          endDate TEXT,
          type TEXT NOT NULL,
          category TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          priority INTEGER NOT NULL DEFAULT 1,
          reminderEnabled INTEGER NOT NULL DEFAULT 1
        )
      ''');
    }
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE activities(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        category TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE daily_tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        category TEXT NOT NULL,
        reminderEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE planner_items(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        startDate TEXT NOT NULL,
        endDate TEXT,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        isCompleted INTEGER NOT NULL DEFAULT 0,
        priority INTEGER NOT NULL DEFAULT 1,
        reminderEnabled INTEGER NOT NULL DEFAULT 1
      )
    ''');
  }

  Future<Activity> create(Activity activity) async {
    final db = await instance.database;
    final id = await db.insert('activities', activity.toMap());
    return activity.copyWith(id: id);
  }

  Future<Activity?> readActivity(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'activities',
      columns: ['id', 'title', 'startTime', 'endTime', 'category', 'notes'],
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Activity.fromMap(maps.first);
    }
    return null;
  }

  Future<List<Activity>> readAllActivities() async {
    final db = await instance.database;
    final result = await db.query('activities', orderBy: 'startTime DESC');
    return result.map((json) => Activity.fromMap(json)).toList();
  }

  Future<int> update(Activity activity) async {
    final db = await instance.database;
    return db.update(
      'activities',
      activity.toMap(),
      where: 'id = ?',
      whereArgs: [activity.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'activities',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<DailyTask> createDailyTask(DailyTask task) async {
    final db = await instance.database;
    final id = await db.insert('daily_tasks', task.toMap());
    return task.copyWith(id: id);
  }

  Future<List<DailyTask>> readAllDailyTasks() async {
    final db = await instance.database;
    final result = await db.query('daily_tasks');
    return result.map((json) => DailyTask.fromMap(json)).toList();
  }

  Future<int> updateDailyTask(DailyTask task) async {
    final db = await instance.database;
    return db.update(
      'daily_tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteDailyTask(int id) async {
    final db = await instance.database;
    return await db.delete(
      'daily_tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> resetDailyTasks() async {
    final db = await instance.database;
    await db.update(
      'daily_tasks',
      {'isCompleted': 0},
    );
  }

  Future<PlannerItem> createPlannerItem(PlannerItem item) async {
    final db = await instance.database;
    final id = await db.insert('planner_items', item.toMap());
    return item.copyWith(id: id);
  }

  Future<List<PlannerItem>> readAllPlannerItems() async {
    final db = await instance.database;
    final result = await db.query('planner_items');
    return result.map((json) => PlannerItem.fromMap(json)).toList();
  }

  Future<int> updatePlannerItem(PlannerItem item) async {
    final db = await instance.database;
    return db.update(
      'planner_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<int> deletePlannerItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'planner_items',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
