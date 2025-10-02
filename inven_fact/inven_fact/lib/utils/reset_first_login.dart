import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResetFirstLogin {
  static const String _databaseName = "sellers.db";
  static const String _tableName = 'sellers';
  static const String _isFirstLoginKey = 'is_first_login';

  /// Resetea el estado de primer login para poder probar los cambios
  static Future<void> resetFirstLoginState() async {
    try {
      // 1. Resetear en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstLoginKey, true);
      
      // 2. Resetear en la base de datos
      String path = join(await getDatabasesPath(), _databaseName);
      Database db = await openDatabase(path);
      
      // Actualizar todos los vendedores para que tengan is_first_login = 1
      await db.update(
        _tableName,
        {'is_first_login': 1},
        where: 'is_active = ?',
        whereArgs: [1],
      );
      
      await db.close();
      
      print('✅ Estado de primer login reseteado exitosamente');
      print('📝 Ahora puedes probar el flujo de cambio de contraseña');
    } catch (e) {
      print('❌ Error al resetear el estado: $e');
    }
  }

  /// Resetea solo el vendedor específico
  static Future<void> resetSpecificSeller(String sellerId) async {
    try {
      // 1. Resetear en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_isFirstLoginKey, true);
      
      // 2. Resetear en la base de datos
      String path = join(await getDatabasesPath(), _databaseName);
      Database db = await openDatabase(path);
      
      // Actualizar solo el vendedor específico
      await db.update(
        _tableName,
        {'is_first_login': 1},
        where: 'id = ? AND is_active = ?',
        whereArgs: [sellerId, 1],
      );
      
      await db.close();
      
      print('✅ Estado de primer login reseteado para $sellerId');
    } catch (e) {
      print('❌ Error al resetear el estado: $e');
    }
  }

  /// Muestra el estado actual de todos los vendedores
  static Future<void> showSellersStatus() async {
    try {
      String path = join(await getDatabasesPath(), _databaseName);
      Database db = await openDatabase(path);
      
      final List<Map<String, dynamic>> maps = await db.query(
        _tableName,
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );
      
      print('📊 Estado actual de vendedores:');
      print('─' * 50);
      
      for (var seller in maps) {
        final isFirstLogin = (seller['is_first_login'] ?? 1) == 1;
        final lastLogin = seller['last_login'] != null 
            ? DateTime.fromMillisecondsSinceEpoch(seller['last_login'])
            : 'Nunca';
        
        print('ID: ${seller['id']}');
        print('Nombre: ${seller['name']}');
        print('Primer Login: ${isFirstLogin ? 'SÍ' : 'NO'}');
        print('Último Login: $lastLogin');
        print('─' * 30);
      }
      
      await db.close();
    } catch (e) {
      print('❌ Error al obtener estado: $e');
    }
  }

  /// Resetea completamente la base de datos de vendedores
  static Future<void> resetAllSellers() async {
    try {
      // 1. Limpiar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 2. Eliminar base de datos
      String path = join(await getDatabasesPath(), _databaseName);
      await deleteDatabase(path);
      
      print('✅ Base de datos de vendedores reseteada completamente');
      print('📝 La próxima vez que inicies sesión se creará todo de nuevo');
    } catch (e) {
      print('❌ Error al resetear completamente: $e');
    }
  }
}
