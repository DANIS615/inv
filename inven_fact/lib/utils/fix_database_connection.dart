import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import '../utils/database_helper.dart';
import '../services/seller_service.dart';
import '../models/seller.dart';

class FixDatabaseConnection {
  /// Reparar completamente la conexión a la base de datos
  static Future<void> fixDatabaseConnection() async {
    print('🔧 INICIANDO REPARACIÓN DE BASE DE DATOS');
    print('=' * 50);
    
    try {
      // 1. Limpiar SharedPreferences
      print('\n🧹 1. LIMPIANDO SHAREDPREFERENCES...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences limpiado');

      // 2. Eliminar archivo de base de datos corrupto
      print('\n🗑️ 2. ELIMINANDO BASE DE DATOS CORRUPTA...');
      try {
        final dbPath = await DatabaseHelper.getDatabasePath();
        final dbFile = File(dbPath);
        if (await dbFile.exists()) {
          await dbFile.delete();
          print('✅ Base de datos corrupta eliminada: $dbPath');
        } else {
          print('ℹ️ No se encontró base de datos existente');
        }
      } catch (e) {
        print('⚠️ Error al eliminar base de datos: $e');
      }

      // 3. Crear directorio de documentos si no existe
      print('\n📁 3. VERIFICANDO DIRECTORIO DE DOCUMENTOS...');
      try {
        final documentsDir = await getApplicationDocumentsDirectory();
        if (!await documentsDir.exists()) {
          await documentsDir.create(recursive: true);
          print('✅ Directorio de documentos creado');
        } else {
          print('✅ Directorio de documentos existe');
        }
      } catch (e) {
        print('❌ Error con directorio de documentos: $e');
        throw e;
      }

      // 4. Inicializar nueva base de datos
      print('\n🆕 4. CREANDO NUEVA BASE DE DATOS...');
      final newDb = await DatabaseHelper.initializeDatabase();
      print('✅ Nueva base de datos creada exitosamente');

      // 5. Verificar que la base de datos funciona
      print('\n🔍 5. VERIFICANDO FUNCIONAMIENTO...');
      final sellerService = SellerService();
      final sellers = await sellerService.getAllSellers();
      print('✅ Base de datos funcional. Vendedores encontrados: ${sellers.length}');

      // 6. Crear VENDEDOR001 si no existe
      print('\n👤 6. CREANDO VENDEDOR001...');
      final vendedor001 = await sellerService.getSellerById('VENDEDOR001');
      if (vendedor001 == null) {
        final newSeller = Seller(
          id: 'VENDEDOR001',
          name: 'Vendedor Principal',
          password: '123456',
          isFirstLogin: true,
          createdAt: DateTime.now(),
        );
        await sellerService.addSeller(newSeller);
        print('✅ VENDEDOR001 creado');
      } else {
        print('✅ VENDEDOR001 ya existe');
      }

      // 7. Configurar SharedPreferences
      print('\n⚙️ 7. CONFIGURANDO SHAREDPREFERENCES...');
      await prefs.setBool('database_initialized', true);
      await prefs.setString('app_version', '1.0.0');
      print('✅ SharedPreferences configurado');

      print('\n' + '=' * 50);
      print('🎉 REPARACIÓN COMPLETADA EXITOSAMENTE');
      print('📝 Credenciales por defecto:');
      print('   ID: VENDEDOR001');
      print('   Contraseña: 123456');
      print('=' * 50);

    } catch (e, stackTrace) {
      print('\n❌ ERROR DURANTE LA REPARACIÓN:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Verificar si la base de datos está funcionando correctamente
  static Future<bool> isDatabaseWorking() async {
    try {
      print('🔍 Verificando estado de la base de datos...');
      
      // Verificar accesibilidad
      final isAccessible = await DatabaseHelper.isDatabaseAccessible();
      if (!isAccessible) {
        print('❌ Base de datos no accesible');
        return false;
      }

      // Verificar que se puede leer
      final sellerService = SellerService();
      final sellers = await sellerService.getAllSellers();
      print('✅ Base de datos funcionando. Vendedores: ${sellers.length}');
      
      return true;
    } catch (e) {
      print('❌ Error en verificación: $e');
      return false;
    }
  }

  /// Reinicializar solo la base de datos sin tocar SharedPreferences
  static Future<void> reinitializeDatabaseOnly() async {
    print('🔄 REINICIALIZANDO SOLO LA BASE DE DATOS');
    print('=' * 40);
    
    try {
      // Eliminar base de datos existente
      final dbPath = await DatabaseHelper.getDatabasePath();
      final dbFile = File(dbPath);
      if (await dbFile.exists()) {
        await dbFile.delete();
        print('✅ Base de datos anterior eliminada');
      }

      // Crear nueva base de datos
      await DatabaseHelper.initializeDatabase();
      print('✅ Nueva base de datos creada');

      // Verificar funcionamiento
      final sellerService = SellerService();
      final sellers = await sellerService.getAllSellers();
      print('✅ Verificación exitosa. Vendedores: ${sellers.length}');

    } catch (e) {
      print('❌ Error en reinicialización: $e');
      rethrow;
    }
  }

  /// Crear un backup de la base de datos actual
  static Future<String?> createBackup() async {
    try {
      final dbPath = await DatabaseHelper.getDatabasePath();
      final dbFile = File(dbPath);
      
      if (await dbFile.exists()) {
        final backupPath = '${dbPath}.backup.${DateTime.now().millisecondsSinceEpoch}';
        await dbFile.copy(backupPath);
        print('✅ Backup creado: $backupPath');
        return backupPath;
      } else {
        print('ℹ️ No hay base de datos para hacer backup');
        return null;
      }
    } catch (e) {
      print('❌ Error creando backup: $e');
      return null;
    }
  }

  /// Restaurar desde un backup
  static Future<void> restoreFromBackup(String backupPath) async {
    try {
      final backupFile = File(backupPath);
      if (await backupFile.exists()) {
        final dbPath = await DatabaseHelper.getDatabasePath();
        await backupFile.copy(dbPath);
        print('✅ Backup restaurado desde: $backupPath');
      } else {
        print('❌ Archivo de backup no encontrado: $backupPath');
      }
    } catch (e) {
      print('❌ Error restaurando backup: $e');
      rethrow;
    }
  }
}
