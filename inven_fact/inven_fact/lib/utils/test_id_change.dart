import 'package:inven_fact/services/seller_service.dart';
import 'package:inven_fact/services/auth_service.dart';
import 'package:inven_fact/models/seller.dart';

class TestIdChange {
  static final SellerService _sellerService = SellerService();
  static final AuthService _authService = AuthService();

  /// Prueba el cambio de ID de vendedor
  static Future<void> testIdChange() async {
    print('🧪 Iniciando prueba de cambio de ID...');
    
    try {
      // 1. Mostrar vendedores actuales
      print('\n📊 Vendedores antes del cambio:');
      await _showSellers();
      
      // 2. Hacer login con VENDEDOR001
      print('\n🔐 Haciendo login con VENDEDOR001...');
      final loginSuccess = await _authService.loginSeller('VENDEDOR001', '123456');
      if (!loginSuccess) {
        print('❌ Error: No se pudo hacer login con VENDEDOR001');
        return;
      }
      print('✅ Login exitoso');
      
      // 3. Cambiar ID a RANDY001
      print('\n🔄 Cambiando ID a RANDY001...');
      final idChangeSuccess = await _authService.changeSellerId('RANDY001');
      if (!idChangeSuccess) {
        print('❌ Error: No se pudo cambiar el ID');
        return;
      }
      print('✅ ID cambiado exitosamente');
      
      // 4. Mostrar vendedores después del cambio
      print('\n📊 Vendedores después del cambio:');
      await _showSellers();
      
      // 5. Verificar que se puede hacer login con el nuevo ID
      print('\n🔐 Probando login con nuevo ID RANDY001...');
      await _authService.logoutSeller();
      final newLoginSuccess = await _authService.loginSeller('RANDY001', '123456');
      if (newLoginSuccess) {
        print('✅ Login con nuevo ID exitoso');
        print('🎉 ¡El cambio de ID funciona correctamente!');
      } else {
        print('❌ Error: No se pudo hacer login con el nuevo ID');
      }
      
    } catch (e) {
      print('❌ Error durante la prueba: $e');
    }
  }

  /// Muestra todos los vendedores
  static Future<void> _showSellers() async {
    try {
      final sellers = await _sellerService.getAllSellers();
      if (sellers.isEmpty) {
        print('   No hay vendedores registrados');
      } else {
        for (var seller in sellers) {
          print('   ID: ${seller.id}, Nombre: ${seller.name}, Primer Login: ${seller.isFirstLogin}');
        }
      }
    } catch (e) {
      print('   Error al obtener vendedores: $e');
    }
  }

  /// Limpia la base de datos para pruebas
  static Future<void> cleanDatabase() async {
    print('🧹 Limpiando base de datos...');
    try {
      await _sellerService.resetAllSellers();
      print('✅ Base de datos limpiada');
    } catch (e) {
      print('❌ Error al limpiar: $e');
    }
  }
}
