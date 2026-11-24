import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:smartcart/models/models.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('smart_cart.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: _onConfigure,
      onCreate: _createDB,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE app_session (
        id INTEGER PRIMARY KEY,
        user_id INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE shopping_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        category TEXT NOT NULL,
        planned_qty REAL NOT NULL,
        actual_qty REAL NOT NULL,
        unit TEXT NOT NULL,
        price REAL NOT NULL,
        is_bought INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE price_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        item_id INTEGER NOT NULL,
        price REAL NOT NULL,
        recorded_at TEXT NOT NULL,
        FOREIGN KEY (item_id) REFERENCES shopping_items (id) ON DELETE CASCADE
      )
    ''');
  }


  Future<UserModel> registerUser({
    required String name,
    required String email,
    required String password,
  }) async {
    final db = await database;
    final normalizedEmail = email.trim().toLowerCase();

    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [normalizedEmail],
    );
    if (existing.isNotEmpty) {
      throw Exception('Користувач із таким email уже зареєстрований');
    }

    final user = UserModel(
      name: name.trim(),
      email: normalizedEmail,
      password: password,
    );

    final id = await db.insert('users', user.toMap());
    await _saveSession(id);

    return UserModel(
      id: id,
      name: user.name,
      email: user.email,
      password: user.password,
    );
  }

  Future<UserModel?> loginUser({
    required String email,
    required String password,
  }) async {
    final db = await database;
    final maps = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email.trim().toLowerCase(), password],
    );

    if (maps.isEmpty) return null;

    final user = UserModel.fromMap(maps.first);
    await _saveSession(user.id!);
    return user;
  }

  Future<void> _saveSession(int userId) async {
    final db = await database;
    await db.insert(
      'app_session',
      {'id': 1, 'user_id': userId},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<UserModel?> getCurrentUser() async {
    final db = await database;
    final session = await db.query('app_session', where: 'id = 1');
    if (session.isEmpty) return null;

    final userId = session.first['user_id'] as int;
    final users = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );

    if (users.isEmpty) return null;
    return UserModel.fromMap(users.first);
  }

  Future<void> logout() async {
    final db = await database;
    await db.delete('app_session');
  }

  Future<bool> deleteAccount({
    required int userId,
    required String password,
  }) async {
    final db = await database;
    final users = await db.query(
      'users',
      where: 'id = ? AND password = ?',
      whereArgs: [userId, password],
    );

    if (users.isEmpty) return false;

    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    return true;
  }


  Future<int> insertItem(ShoppingItem item) async {
    final db = await database;
    final itemId = await db.insert('shopping_items', item.toMap());

    await db.insert(
      'price_history',
      PriceHistory(
        itemId: itemId,
        price: item.price,
        recordedAt: DateTime.now(),
      ).toMap(),
    );

    return itemId;
  }

  Future<List<ShoppingItem>> getItemsByUser(int userId) async {
    final db = await database;
    final maps = await db.query(
      'shopping_items',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'is_bought ASC, id DESC',
    );
    return maps.map((map) => ShoppingItem.fromMap(map)).toList();
  }

  Future<void> updateItem(ShoppingItem item) async {
    final db = await database;
    if (item.id == null) return;

    final currentMaps = await db.query(
      'shopping_items',
      columns: ['price'],
      where: 'id = ?',
      whereArgs: [item.id],
    );

    await db.update(
      'shopping_items',
      item.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );

    if (currentMaps.isNotEmpty) {
      final oldPrice = (currentMaps.first['price'] as num).toDouble();
      if ((oldPrice - item.price).abs() > 0.001) {
        await db.insert(
          'price_history',
          PriceHistory(
            itemId: item.id!,
            price: item.price,
            recordedAt: DateTime.now(),
          ).toMap(),
        );
      }
    }
  }

  Future<void> toggleItemBought(int itemId, bool isBought) async {
    final db = await database;
    await db.update(
      'shopping_items',
      {'is_bought': isBought ? 1 : 0},
      where: 'id = ?',
      whereArgs: [itemId],
    );
  }

  Future<void> deleteItem(int itemId) async {
    final db = await database;
    await db.delete('shopping_items', where: 'id = ?', whereArgs: [itemId]);
  }

  Future<List<PriceHistory>> getPriceHistory(int itemId) async {
    final db = await database;
    final maps = await db.query(
      'price_history',
      where: 'item_id = ?',
      whereArgs: [itemId],
      orderBy: 'id DESC',
    );
    return maps.map((map) => PriceHistory.fromMap(map)).toList();
  }
}