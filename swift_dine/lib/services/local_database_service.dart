import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseService {
  static final LocalDatabaseService _instance = LocalDatabaseService._internal();
  factory LocalDatabaseService() => _instance;
  LocalDatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'swiftdine.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users(
        id TEXT PRIMARY KEY,
        email TEXT NOT NULL,
        full_name TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Orders table
    await db.execute('''
      CREATE TABLE orders(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        restaurant TEXT NOT NULL,
        items TEXT NOT NULL,
        total_amount REAL NOT NULL,
        status TEXT NOT NULL,
        created_at TEXT NOT NULL,
        delivery_address TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        payment_status TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');

    // Favorites table
    await db.execute('''
      CREATE TABLE favorites(
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        restaurant_id TEXT NOT NULL,
        restaurant_name TEXT NOT NULL,
        restaurant_image TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // Order methods
  Future<void> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('orders', order, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getOrders(String userId) async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
    );
  }

  Future<void> markOrderAsSynced(String orderId) async {
    final db = await database;
    await db.update(
      'orders',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  // Sync methods
  Future<List<Map<String, dynamic>>> getUnsyncedOrders() async {
    final db = await database;
    return await db.query(
      'orders',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }
}