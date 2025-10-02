import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'database_helper.dart';

class ResetApp {
  /// Reset completo de la aplicación
  static Future<void> resetCompleteApp() async {
    try {
      // 1. Limpiar SharedPreferences (incluyendo configuración de empresa)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // 2. Eliminar base de datos corrupta
      try {
        await DatabaseHelper.clearDatabase();
      } catch (e) {
        // Ignorar errores de eliminación
      }
      
      // 3. Configurar VENDEDOR001 en SharedPreferences solamente
      await prefs.setString('current_seller_id', 'VENDEDOR001');
      await prefs.setString('current_seller_name', 'Vendedor Principal');
      await prefs.setString('current_seller_password', '123456');
      await prefs.setBool('isFirstLogin', true);
      
      // 4. Configurar flags de autenticación para evitar problemas
      await prefs.setBool('seller_logged_in', false);
      await prefs.setBool('remember_me', false);
      
    } catch (e) {
      rethrow;
    }
  }
  
  /// Verificar estado de la aplicación
  static Future<void> checkAppStatus() async {
    try {
      // Verificar SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      String? sellerId = prefs.getString('current_seller_id');
      String? sellerName = prefs.getString('current_seller_name');
      bool? isFirstLogin = prefs.getBool('isFirstLogin');
      
      // Verificar base de datos
      bool dbAccessible = await DatabaseHelper.isDatabaseAccessible();
      
      if (dbAccessible) {
        try {
          await DatabaseHelper.initializeDatabase();
        } catch (e) {
          // Error al abrir base de datos
        }
      }
      
    } catch (e) {
      // Error al verificar estado
    }
  }
}
