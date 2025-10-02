import 'package:inven_fact/services/seller_service.dart';
import 'package:inven_fact/services/auth_service.dart';
import 'package:inven_fact/models/seller.dart';
import 'package:inven_fact/utils/database_helper.dart';

class DebugDatabaseConnection {
  static final SellerService _sellerService = SellerService();
  static final AuthService _authService = AuthService();

  /// Diagnóstico completo de la conexión a la base de datos
  static Future<void> runFullDiagnostic() async {
    print('🔍 INICIANDO DIAGNÓSTICO COMPLETO DE BASE DE DATOS');
    print('=' * 60);
    
    try {
      // 1. Verificar si la base de datos es accesible
      print('\n📊 1. VERIFICANDO ACCESIBILIDAD DE BASE DE DATOS...');
      final isAccessible = await DatabaseHelper.isDatabaseAccessible();
      print('✅ Base de datos accesible: $isAccessible');
      
      if (!isAccessible) {
        print('❌ PROBLEMA: La base de datos no es accesible');
        return;
      }

      // 2. Obtener la ruta de la base de datos
      print('\n📁 2. RUTA DE BASE DE DATOS...');
      final dbPath = await DatabaseHelper.getDatabasePath();
      print('📍 Ruta: $dbPath');

      // 3. Verificar todos los vendedores en la base de datos
      print('\n👥 3. VERIFICANDO VENDEDORES EN BASE DE DATOS...');
      final allSellers = await _sellerService.getAllSellers();
      print('📊 Total de vendedores encontrados: ${allSellers.length}');
      
      for (var seller in allSellers) {
        print('\n🔍 Vendedor:');
        print('   ID: ${seller.id}');
        print('   Nombre: ${seller.name}');
        print('   Contraseña: ${seller.password}');
        print('   Primer Login: ${seller.isFirstLogin}');
        print('   Activo: ${seller.isActive}');
        print('   Último Login: ${seller.lastLogin}');
        print('   Creado: ${seller.createdAt}');
      }

      // 4. Probar autenticación con credenciales por defecto
      print('\n🔐 4. PROBANDO AUTENTICACIÓN...');
      final testId = 'VENDEDOR001';
      final testPassword = '123456';
      
      print('🧪 Probando con ID: $testId, Password: $testPassword');
      
      final authResult = await _sellerService.authenticateSeller(testId, testPassword);
      if (authResult != null) {
        print('✅ AUTENTICACIÓN EXITOSA');
        print('   Vendedor autenticado: ${authResult.name}');
        print('   Es primer login: ${authResult.isFirstLogin}');
      } else {
        print('❌ AUTENTICACIÓN FALLÓ');
        
        // Probar sin filtro de activo
        print('\n🔍 Probando sin filtro de activo...');
        final unfilteredResult = await _sellerService.getSellerByIdUnfiltered(testId);
        if (unfilteredResult != null) {
          print('⚠️ Vendedor encontrado sin filtro:');
          print('   ID: ${unfilteredResult.id}');
          print('   Activo: ${unfilteredResult.isActive}');
          print('   Contraseña: ${unfilteredResult.password}');
        } else {
          print('❌ Vendedor no encontrado en absoluto');
        }
      }

      // 5. Probar el servicio de autenticación completo
      print('\n🔑 5. PROBANDO SERVICIO DE AUTENTICACIÓN COMPLETO...');
      final loginResult = await _authService.loginSeller(testId, testPassword);
      print('🔐 Resultado del login: $loginResult');
      
      if (loginResult) {
        print('✅ LOGIN EXITOSO');
        print('   Vendedor logueado: ${_authService.sellerName}');
        print('   ID: ${_authService.sellerId}');
        print('   Es primer login: ${_authService.isFirstLogin}');
      } else {
        print('❌ LOGIN FALLÓ');
      }

      // 6. Verificar estado de autenticación
      print('\n📋 6. ESTADO ACTUAL DE AUTENTICACIÓN...');
      print('   Está logueado: ${_authService.isSellerLoggedIn}');
      print('   Es autenticado: ${_authService.isAuthenticated()}');
      print('   Nombre: ${_authService.sellerName}');
      print('   ID: ${_authService.sellerId}');

    } catch (e, stackTrace) {
      print('\n❌ ERROR DURANTE EL DIAGNÓSTICO:');
      print('   Error: $e');
      print('   Stack trace: $stackTrace');
    }
    
    print('\n' + '=' * 60);
    print('🏁 DIAGNÓSTICO COMPLETADO');
  }

  /// Diagnóstico rápido para verificar solo la conexión
  static Future<bool> quickConnectionTest() async {
    try {
      print('🔍 Prueba rápida de conexión...');
      
      // Verificar accesibilidad
      final isAccessible = await DatabaseHelper.isDatabaseAccessible();
      if (!isAccessible) {
        print('❌ Base de datos no accesible');
        return false;
      }
      
      // Intentar obtener vendedores
      final sellers = await _sellerService.getAllSellers();
      print('✅ Conexión exitosa. Vendedores encontrados: ${sellers.length}');
      
      return true;
    } catch (e) {
      print('❌ Error en prueba rápida: $e');
      return false;
    }
  }

  /// Reinicializar la base de datos si es necesario
  static Future<void> resetDatabaseIfNeeded() async {
    try {
      print('🔄 Verificando si es necesario reinicializar la base de datos...');
      
      final isAccessible = await DatabaseHelper.isDatabaseAccessible();
      if (!isAccessible) {
        print('🔄 Base de datos no accesible, reinicializando...');
        await DatabaseHelper.clearDatabase();
        await DatabaseHelper.initializeDatabase();
        print('✅ Base de datos reinicializada');
      } else {
        print('✅ Base de datos accesible, no se necesita reinicialización');
      }
    } catch (e) {
      print('❌ Error al reinicializar base de datos: $e');
    }
  }
}
