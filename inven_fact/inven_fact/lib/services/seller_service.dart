import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/seller.dart';
import '../utils/database_helper.dart';

class SellerService {
  static const _databaseName = "sellers.db";
  static const _databaseVersion = 1;
  static const _tableName = 'sellers';

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnPassword = 'password';
  static const columnIsFirstLogin = 'is_first_login';
  static const columnCreatedAt = 'created_at';
  static const columnLastLogin = 'last_login';
  static const columnIsActive = 'is_active';

  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  _initDatabase() async {
    try {
      return await DatabaseHelper.initializeDatabase();
    } catch (e) {
      print('❌ ERROR SellerService: Error al abrir base de datos: $e');
      rethrow;
    }
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_tableName (
            $columnId TEXT PRIMARY KEY,
            $columnName TEXT NOT NULL,
            $columnPassword TEXT NOT NULL,
            $columnIsFirstLogin INTEGER NOT NULL DEFAULT 1,
            $columnCreatedAt INTEGER NOT NULL,
            $columnLastLogin INTEGER,
            $columnIsActive INTEGER NOT NULL DEFAULT 1
          )
          ''');
    
    // Insertar vendedor por defecto
    await _insertDefaultSeller(db);
  }

  Future<void> _insertDefaultSeller(Database db) async {
    final defaultSeller = Seller(
      id: 'VENDEDOR001',
      name: 'Vendedor Principal',
      password: '123456',
      isFirstLogin: true,
      createdAt: DateTime.now(),
    );
    
    await db.insert(_tableName, defaultSeller.toMap());
  }

  Future<int> addSeller(Seller seller) async {
    Database db = await database;
    return await db.insert(_tableName, seller.toMap());
  }

  Future<List<Seller>> getSellers() async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnIsActive = ?',
      whereArgs: [1],
      orderBy: '$columnCreatedAt DESC',
    );

    return List.generate(maps.length, (i) {
      return Seller.fromMap(maps[i]);
    });
  }

  Future<Seller?> getSellerById(String id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnId = ? AND $columnIsActive = ?',
      whereArgs: [id, 1],
    );

    if (maps.isNotEmpty) {
      return Seller.fromMap(maps.first);
    }
    return null;
  }

  /// Obtiene un vendedor por ID sin filtrar por isActive (para debug)
  Future<Seller?> getSellerByIdUnfiltered(String id) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Seller.fromMap(maps.first);
    }
    return null;
  }

  Future<Seller?> authenticateSeller(String id, String password) async {
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnId = ? AND $columnPassword = ? AND $columnIsActive = ?',
      whereArgs: [id, password, 1],
    );

    if (maps.isNotEmpty) {
      return Seller.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateSeller(Seller seller) async {
    Database db = await database;
    return await db.update(
      _tableName, 
      seller.toMap(),
      where: '$columnId = ?', 
      whereArgs: [seller.id],
    );
  }

  Future<int> updateLastLogin(String sellerId) async {
    Database db = await database;
    return await db.update(
      _tableName,
      {columnLastLogin: DateTime.now().millisecondsSinceEpoch},
      where: '$columnId = ?',
      whereArgs: [sellerId],
    );
  }

  Future<int> changePassword(String sellerId, String newPassword) async {
    Database db = await database;
    return await db.update(
      _tableName,
      {
        columnPassword: newPassword,
        columnIsFirstLogin: 0, // Ya no es primer login
      },
      where: '$columnId = ?',
      whereArgs: [sellerId],
    );
  }

  Future<int> updateSellerName(String sellerId, String newName) async {
    Database db = await database;
    return await db.update(
      _tableName,
      {columnName: newName},
      where: '$columnId = ?',
      whereArgs: [sellerId],
    );
  }

  Future<int> deactivateSeller(String sellerId) async {
    Database db = await database;
    return await db.update(
      _tableName,
      {columnIsActive: 0},
      where: '$columnId = ?',
      whereArgs: [sellerId],
    );
  }

  Future<int> deleteSeller(String sellerId) async {
    Database db = await database;
    return await db.delete(_tableName, where: '$columnId = ?', whereArgs: [sellerId]);
  }

  /// Obtiene todos los vendedores (alias para getSellers)
  Future<List<Seller>> getAllSellers() async {
    return await getSellers();
  }

  /// Resetea el estado de primer login para un vendedor específico
  Future<void> resetFirstLoginState() async {
    Database db = await database;
    await db.update(
      _tableName,
      {columnIsFirstLogin: 1},
      where: '$columnId = ?',
      whereArgs: ['VENDEDOR001'], // Solo para el vendedor por defecto
    );
  }

  /// Resetea todos los vendedores (elimina y recrea)
  Future<void> resetAllSellers() async {
    Database db = await database;
    await db.delete(_tableName); // Elimina todos los vendedores
    await _insertDefaultSeller(db); // Vuelve a insertar el vendedor por defecto
  }

}
