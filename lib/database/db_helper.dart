import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'todo_database.db');
      return await openDatabase(
        path, 
        version: 1, 
        onCreate: _onCreate,
        onOpen: (db) => debugPrint("Database opened successfully"),
      );
    } catch (e) {
      debugPrint("Database initialization failed: $e");
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        description TEXT,
        dateTime INTEGER NOT NULL,
        done INTEGER NOT NULL DEFAULT 0
      )
    ''');
    debugPrint("Tasks table created successfully");
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    try {
      final Database db = await database;
      return await db.query('tasks', orderBy: 'dateTime ASC');
    } catch (e) {
      debugPrint("Error fetching tasks: $e");
      return [];
    }
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    try {
      final Database db = await database;
      return await db.insert('tasks', task);
    } catch (e) {
      debugPrint("Database insert error: $e");
      rethrow;
    }
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    try {
      final Database db = await database;
      return await db.update(
        'tasks',
        task,
        where: 'id = ?',
        whereArgs: [task['id']],
      );
    } catch (e) {
      debugPrint("Database update error: $e");
      rethrow;
    }
  }

  Future<int> deleteTask(int id) async {
    try {
      final Database db = await database;
      return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      debugPrint("Database delete error: $e");
      rethrow;
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}