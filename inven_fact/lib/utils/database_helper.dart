import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DatabaseHelper {
  static const String _databaseName = "inven_fact.db";
  static const int _databaseVersion = 1;

  /// Obtener la ruta de la base de datos de forma segura
  static Future<String> getDatabasePath() async {
    try {
      Directory documentsDirectory = await getApplicationDocumentsDirectory();
      String path = join(documentsDirectory.path, _databaseName);
      print('🔍 DEBUG DatabaseHelper: Ruta de base de datos: $path');
      return path;
    } catch (e) {
      print('❌ ERROR DatabaseHelper: Error al obtener ruta: $e');
      rethrow;
    }
  }

  /// Inicializar la base de datos de forma segura
  static Future<Database> initializeDatabase() async {
    try {
      String path = await getDatabasePath();
      
      return await openDatabase(
        path,
        version: _databaseVersion,
        onCreate: _onCreate,
        onOpen: (db) {
          print('🔍 DEBUG DatabaseHelper: Base de datos abierta correctamente');
        },
        onConfigure: (db) {
          print('🔍 DEBUG DatabaseHelper: Configurando base de datos');
        },
      );
    } catch (e) {
      print('❌ ERROR DatabaseHelper: Error al inicializar base de datos: $e');
      rethrow;
    }
  }

  /// Crear las tablas necesarias
  static Future<void> _onCreate(Database db, int version) async {
    print('🔍 DEBUG DatabaseHelper: Creando tablas...');
    
    // Crear tabla de vendedores
    await db.execute('''
      CREATE TABLE sellers (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        password TEXT NOT NULL,
        is_first_login INTEGER NOT NULL DEFAULT 1,
        created_at INTEGER NOT NULL,
        last_login INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    // Crear tabla de clientes
    await db.execute('''
      CREATE TABLE clients_general (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        code TEXT NOT NULL,
        account_type TEXT NOT NULL DEFAULT 'contado',
        pending_balance REAL NOT NULL DEFAULT 0.0,
        last_purchase INTEGER,
        is_active INTEGER NOT NULL DEFAULT 1,
        rnc TEXT,
        cedula TEXT,
        direccion TEXT,
        telefono TEXT,
        email TEXT
      )
    ''');

    // Insertar vendedor por defecto
    await _insertDefaultSeller(db);
    
    print('✅ DEBUG DatabaseHelper: Tablas creadas correctamente');
  }

  /// Insertar vendedor por defecto
  static Future<void> _insertDefaultSeller(Database db) async {
    try {
      final defaultSeller = {
        'id': 'VENDEDOR001',
        'name': 'Vendedor Principal',
        'password': '123456',
        'is_first_login': 1,
        'created_at': DateTime.now().millisecondsSinceEpoch,
        'is_active': 1,
      };
      
      await db.insert('sellers', defaultSeller);
      print('✅ DEBUG DatabaseHelper: VENDEDOR001 creado correctamente');
    } catch (e) {
      print('⚠️ DEBUG DatabaseHelper: VENDEDOR001 ya existe o error: $e');
    }
  }

  /// Verificar si la base de datos existe y es accesible
  static Future<bool> isDatabaseAccessible() async {
    try {
      String path = await getDatabasePath();
      File dbFile = File(path);
      bool exists = await dbFile.exists();
      print('🔍 DEBUG DatabaseHelper: Base de datos existe: $exists');
      return exists;
    } catch (e) {
      print('❌ ERROR DatabaseHelper: Error al verificar base de datos: $e');
      return false;
    }
  }

  /// Limpiar base de datos (eliminar archivo)
  static Future<void> clearDatabase() async {
    try {
      String path = await getDatabasePath();
      File dbFile = File(path);
      if (await dbFile.exists()) {
        await dbFile.delete();
        print('✅ DEBUG DatabaseHelper: Base de datos eliminada');
      }
    } catch (e) {
      print('❌ ERROR DatabaseHelper: Error al limpiar base de datos: $e');
      rethrow;
    }
  }
}
