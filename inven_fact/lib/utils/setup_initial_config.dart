import 'package:shared_preferences/shared_preferences.dart';

class SetupInitialConfig {
  /// Configurar SharedPreferences inicial para VENDEDOR001
  static Future<void> setupVendedor001() async {
    try {
      print('🔧 === CONFIGURANDO VENDEDOR001 EN SHAREDPREFERENCES ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Configurar VENDEDOR001 como vendedor por defecto
      await prefs.setString('current_seller_id', 'VENDEDOR001');
      await prefs.setString('current_seller_name', 'Vendedor Principal');
      await prefs.setString('current_seller_password', '123456');
      await prefs.setBool('isFirstLogin', true);
      
      // Verificar que se guardó correctamente
      String? sellerId = prefs.getString('current_seller_id');
      String? sellerName = prefs.getString('current_seller_name');
      String? sellerPassword = prefs.getString('current_seller_password');
      bool? isFirstLogin = prefs.getBool('isFirstLogin');
      
      print('✅ SharedPreferences configurado:');
      print('   - current_seller_id: $sellerId');
      print('   - current_seller_name: $sellerName');
      print('   - current_seller_password: $sellerPassword');
      print('   - isFirstLogin: $isFirstLogin');
      
      print('✅ VENDEDOR001 configurado correctamente en SharedPreferences');
      
    } catch (e) {
      print('❌ Error al configurar SharedPreferences: $e');
      rethrow;
    }
  }
  
  /// Verificar configuración actual
  static Future<void> checkCurrentConfig() async {
    try {
      print('🔍 === VERIFICANDO CONFIGURACIÓN ACTUAL ===');
      
      final prefs = await SharedPreferences.getInstance();
      
      String? sellerId = prefs.getString('current_seller_id');
      String? sellerName = prefs.getString('current_seller_name');
      String? sellerPassword = prefs.getString('current_seller_password');
      bool? isFirstLogin = prefs.getBool('isFirstLogin');
      
      print('📊 SharedPreferences actual:');
      print('   - current_seller_id: $sellerId');
      print('   - current_seller_name: $sellerName');
      print('   - current_seller_password: $sellerPassword');
      print('   - isFirstLogin: $isFirstLogin');
      
      if (sellerId == null || sellerName == null || sellerPassword == null) {
        print('⚠️ SharedPreferences no está configurado correctamente');
        print('💡 Usa "CONFIGURAR VENDEDOR001" para solucionarlo');
      } else {
        print('✅ SharedPreferences está configurado correctamente');
      }
      
    } catch (e) {
      print('❌ Error al verificar configuración: $e');
    }
  }
}
