import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';
import '../services/seller_service.dart';
import '../services/client_service.dart';

class DatabaseDiagnostic {
  /// Diagnosticar problemas de base de datos
  static Future<void> diagnoseDatabase() async {
    print('🔍 === DIAGNÓSTICO DE BASE DE DATOS ===');
    
    try {
      // 1. Verificar si la base de datos es accesible
      bool isAccessible = await DatabaseHelper.isDatabaseAccessible();
      print('📊 Base de datos accesible: $isAccessible');
      
      if (!isAccessible) {
        print('❌ La base de datos no es accesible');
        return;
      }
      
      // 2. Intentar inicializar la base de datos
      Database db = await DatabaseHelper.initializeDatabase();
      print('✅ Base de datos inicializada correctamente');
      
      // 3. Verificar tablas
      List<Map<String, dynamic>> tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table'"
      );
      print('📋 Tablas encontradas: ${tables.map((t) => t['name']).toList()}');
      
      // 4. Verificar vendedores
      try {
        SellerService sellerService = SellerService();
        List sellers = await sellerService.getSellers();
        print('👥 Vendedores encontrados: ${sellers.length}');
        for (var seller in sellers) {
          print('   - ${seller.name} (${seller.id})');
        }
      } catch (e) {
        print('❌ Error al obtener vendedores: $e');
      }
      
      // 5. Verificar clientes
      try {
        ClientService clientService = ClientService();
        List clients = await clientService.getClients();
        print('👤 Clientes encontrados: ${clients.length}');
        for (var client in clients) {
          print('   - ${client.name} (${client.code})');
        }
      } catch (e) {
        print('❌ Error al obtener clientes: $e');
      }
      
      await db.close();
      print('✅ Diagnóstico completado');
      
    } catch (e) {
      print('❌ Error durante diagnóstico: $e');
    }
  }
  
  /// Crear base de datos desde cero
  static Future<void> recreateDatabase() async {
    print('🔧 === RECREANDO BASE DE DATOS ===');
    
    try {
      // 1. Limpiar base de datos existente
      await DatabaseHelper.clearDatabase();
      print('✅ Base de datos anterior eliminada');
      
      // 2. Crear nueva base de datos
      Database db = await DatabaseHelper.initializeDatabase();
      print('✅ Nueva base de datos creada');
      
      // 3. Verificar que VENDEDOR001 existe
      SellerService sellerService = SellerService();
      List sellers = await sellerService.getSellers();
      print('👥 Vendedores después de recrear: ${sellers.length}');
      
      await db.close();
      print('✅ Base de datos recreada exitosamente');
      
    } catch (e) {
      print('❌ Error al recrear base de datos: $e');
      rethrow;
    }
  }
}
