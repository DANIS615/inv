import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/client.dart';
import 'client_context_service.dart';
import '../utils/database_helper.dart';
import '../utils/event_bus.dart';

class ClientService {
  static const _baseDatabaseName = "clients";
  static const _databaseVersion = 1;
  
  final ClientContextService _clientContext = ClientContextService();
  
  String get _tableName {
    // Siempre usar la tabla general para vendedores
    return 'clients_general';
  }
  
  String get _databaseName {
    // Siempre usar la base de datos general para vendedores
    return '${_baseDatabaseName}_general.db';
  }

  static const columnId = 'id';
  static const columnName = 'name';
  static const columnCode = 'code';
  static const columnAccountType = 'account_type';
  static const columnPendingBalance = 'pending_balance';
  static const columnLastPurchase = 'last_purchase';
  static const columnIsActive = 'is_active';
  static const columnRnc = 'rnc';
  static const columnCedula = 'cedula';
  static const columnDireccion = 'direccion';
  static const columnTelefono = 'telefono';
  static const columnEmail = 'email';

  // Database instance por cliente
  Database? _database;
  Future<Database> get database async {
    if (_database != null) return _database!;
    // lazily instantiate the db the first time it is accessed
    _database = await _initDatabase();
    return _database!;
  }

  // this opens the database (and creates it if it doesn't exist)
  _initDatabase() async {
    try {
      return await DatabaseHelper.initializeDatabase();
    } catch (e) {
      // Error al abrir base de datos
      rethrow;
    }
  }

  // SQL code to create the database table
  Future _onCreate(Database db, int version) async {
    await db.execute('''
          CREATE TABLE $_tableName (
            $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
            $columnName TEXT NOT NULL,
            $columnCode TEXT NOT NULL,
            $columnAccountType TEXT NOT NULL DEFAULT 'contado',
            $columnPendingBalance REAL NOT NULL DEFAULT 0.0,
            $columnLastPurchase INTEGER,
            $columnIsActive INTEGER NOT NULL DEFAULT 1,
            $columnRnc TEXT,
            $columnCedula TEXT,
            $columnDireccion TEXT,
            $columnTelefono TEXT,
            $columnEmail TEXT
          )
          ''');
  }

  // Helper methods

  // Inserts a row in the database where each key in the Map is a column name
  // and the value is the column value. The return value is the id of the
  // inserted row.
  Future<int> addClient(Client client) async {
    // No validar contexto de cliente para operaciones de vendedor
    Database db = await database;
    print('🔍 DEBUG ClientService: Agregando cliente: ${client.name}');
    print('🔍 DEBUG ClientService: Código: ${client.code}');
    print('🔍 DEBUG ClientService: Tipo de cuenta: ${client.accountType}');
    print('🔍 DEBUG ClientService: Datos a insertar: ${client.toMap()}');
    
    final result = await db.insert(_tableName, client.toMap());
    print('🔍 DEBUG ClientService: Cliente insertado con ID: $result');
    
    // Emitir evento para actualizar dashboard
    try {
      EventBus().fire('clientAdded');
      EventBus().fire('clientsChanged');
      print('🔔 DEBUG ClientService: Eventos emitidos: clientAdded, clientsChanged');
    } catch (e) {
      print('❌ ERROR ClientService: Error al emitir eventos: $e');
    }
    
    return result;
  }

  // All of the rows are returned as a list of maps, where each map is
  // a key-value list of columns.
  Future<List<Client>> getClients() async {
    // No validar contexto de cliente para operaciones de vendedor
    Database db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tableName);

    return List.generate(maps.length, (i) {
      return Client.fromMap(maps[i]);
    });
  }

  // We are assuming here that the id column in the map is set. The other
  // column values will be used to update the row.
  Future<int> updateClient(Client client) async {
    // No validar contexto de cliente para operaciones de vendedor
    Database db = await database;
    final result = await db.update(_tableName, client.toMap(),
        where: '$columnId = ?', whereArgs: [client.id]);
    
    // Emitir evento para actualizar dashboard
    if (result > 0) {
      try {
        EventBus().fire('clientUpdated');
        EventBus().fire('clientsChanged');
        print('🔔 DEBUG ClientService: Eventos emitidos: clientUpdated, clientsChanged');
      } catch (e) {
        print('❌ ERROR ClientService: Error al emitir eventos: $e');
      }
    }
    
    return result;
  }

  /// Actualiza un cliente usando el código cuando el id no está disponible
  Future<int> updateClientByCode(Client client) async {
    Database db = await database;
    final result = await db.update(
      _tableName,
      client.toMap(),
      where: '$columnCode = ?',
      whereArgs: [client.code],
    );
    
    // Emitir evento para actualizar dashboard
    if (result > 0) {
      try {
        EventBus().fire('clientUpdated');
        EventBus().fire('clientsChanged');
        print('🔔 DEBUG ClientService: Eventos emitidos: clientUpdated, clientsChanged');
      } catch (e) {
        print('❌ ERROR ClientService: Error al emitir eventos: $e');
      }
    }
    
    return result;
  }

  // Deletes the row specified by the id. The number of affected rows is
  // returned. This should be 1 as long as the row exists.
  Future<int> deleteClient(int id) async {
    // No validar contexto de cliente para operaciones de vendedor
    Database db = await database;
    final result = await db.delete(_tableName, where: '$columnId = ?', whereArgs: [id]);
    
    // Emitir evento para actualizar dashboard
    if (result > 0) {
      try {
        EventBus().fire('clientDeleted');
        EventBus().fire('clientsChanged');
        print('🔔 DEBUG ClientService: Eventos emitidos: clientDeleted, clientsChanged');
      } catch (e) {
        print('❌ ERROR ClientService: Error al emitir eventos: $e');
      }
    }
    
    return result;
  }

  // Obtiene un cliente específico por código
  Future<Client?> getClientByCode(String code) async {
    // No validar contexto de cliente para operaciones de vendedor
    Database db = await database;
    print('🔍 DEBUG ClientService: Buscando cliente con código: $code');
    print('🔍 DEBUG ClientService: Tabla: $_tableName');
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnCode = ?',
      whereArgs: [code],
    );

    print('🔍 DEBUG ClientService: Resultados encontrados: ${maps.length}');
    if (maps.isNotEmpty) {
      print('🔍 DEBUG ClientService: Datos del cliente: ${maps.first}');
      final client = Client.fromMap(maps.first);
      print('🔍 DEBUG ClientService: Cliente parseado - Nombre: ${client.name}, Tipo: ${client.accountType}');
      return client;
    }
    print('🔍 DEBUG ClientService: No se encontró cliente con código: $code');
    return null;
  }

  // Obtiene un cliente específico por ID
  Future<Client?> getClientById(int id) async {
    Database db = await database;
    print('🔍 DEBUG ClientService: Buscando cliente con ID: $id');
    
    final List<Map<String, dynamic>> maps = await db.query(
      _tableName,
      where: '$columnId = ?',
      whereArgs: [id],
    );

    print('🔍 DEBUG ClientService: Resultados encontrados: ${maps.length}');
    if (maps.isNotEmpty) {
      print('🔍 DEBUG ClientService: Datos del cliente: ${maps.first}');
      final client = Client.fromMap(maps.first);
      print('🔍 DEBUG ClientService: Cliente parseado - Nombre: ${client.name}, Tipo: ${client.accountType}');
      return client;
    }
    print('🔍 DEBUG ClientService: No se encontró cliente con ID: $id');
    return null;
  }

}
