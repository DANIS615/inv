import 'package:inven_fact/services/seller_service.dart';
import 'package:inven_fact/services/auth_service.dart';
import 'package:inven_fact/models/seller.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugVendedor001 {
  static final SellerService _sellerService = SellerService();
  static final AuthService _authService = AuthService();

  /// Debug específico para VENDEDOR001
  static Future<void> debugVendedor001() async {
    print('🔍 === DEBUG VENDEDOR001 ===');
    
    try {
      // 1. Verificar SharedPreferences
      print('\n📊 SharedPreferences:');
      final prefs = await SharedPreferences.getInstance();
      String? sellerId = prefs.getString('current_seller_id');
      String? sellerName = prefs.getString('current_seller_name');
      String? sellerPassword = prefs.getString('current_seller_password');
      bool? isFirstLogin = prefs.getBool('isFirstLogin');
      
      print('   - current_seller_id: $sellerId');
      print('   - current_seller_name: $sellerName');
      print('   - current_seller_password: $sellerPassword');
      print('   - isFirstLogin: $isFirstLogin');

      // 2. Verificar todos los vendedores en la base de datos
      print('\n📊 Todos los vendedores en la base de datos:');
      final allSellers = await _sellerService.getAllSellers();
      print('   - Total vendedores: ${allSellers.length}');
      
      for (var seller in allSellers) {
        print('   - ID: ${seller.id}');
        print('   - Nombre: ${seller.name}');
        print('   - Contraseña: ${seller.password}');
        print('   - Primer Login: ${seller.isFirstLogin}');
        print('   - Activo: ${seller.isActive}');
        print('   - Creado: ${seller.createdAt}');
        print('   ─' * 40);
      }

      // 3. Buscar específicamente VENDEDOR001
      print('\n🔍 Buscando VENDEDOR001 específicamente:');
      final vendedor001 = await _sellerService.getSellerById('VENDEDOR001');
      if (vendedor001 != null) {
        print('✅ VENDEDOR001 encontrado:');
        print('   - ID: ${vendedor001.id}');
        print('   - Nombre: ${vendedor001.name}');
        print('   - Contraseña: ${vendedor001.password}');
        print('   - Primer Login: ${vendedor001.isFirstLogin}');
        print('   - Activo: ${vendedor001.isActive}');
      } else {
        print('❌ VENDEDOR001 NO encontrado en la base de datos');
      }

      // 4. Buscar sin filtro de activo
      print('\n🔍 Buscando VENDEDOR001 sin filtro de activo:');
      final vendedor001Unfiltered = await _sellerService.getSellerByIdUnfiltered('VENDEDOR001');
      if (vendedor001Unfiltered != null) {
        print('✅ VENDEDOR001 encontrado (sin filtro):');
        print('   - Activo: ${vendedor001Unfiltered.isActive}');
        print('   - Contraseña: ${vendedor001Unfiltered.password}');
      } else {
        print('❌ VENDEDOR001 NO encontrado (sin filtro)');
      }

      // 5. Probar autenticación directa
      print('\n🔐 Probando autenticación directa VENDEDOR001/123456:');
      final directAuth = await _sellerService.authenticateSeller('VENDEDOR001', '123456');
      if (directAuth != null) {
        print('✅ Autenticación directa exitosa');
        print('   - Vendedor: ${directAuth.name}');
        print('   - Primer Login: ${directAuth.isFirstLogin}');
      } else {
        print('❌ Autenticación directa falló');
      }

      // 6. Probar con AuthService
      print('\n🔐 Probando login con AuthService VENDEDOR001/123456:');
      final authSuccess = await _authService.loginSeller('VENDEDOR001', '123456');
      if (authSuccess) {
        print('✅ Login con AuthService exitoso');
        print('   - Seller ID: ${_authService.sellerId}');
        print('   - Seller Name: ${_authService.sellerName}');
        print('   - Is First Login: ${_authService.isFirstLogin}');
      } else {
        print('❌ Login con AuthService falló');
      }

      // 7. Verificar si hay problemas con la base de datos
      print('\n🔍 Verificando estado de la base de datos:');
      try {
        final db = await _sellerService.database;
        print('✅ Base de datos accesible');
        
        // Verificar tablas
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table'"
        );
        print('   - Tablas encontradas: ${tables.map((t) => t['name']).toList()}');
        
        // Verificar estructura de la tabla sellers
        final columns = await db.rawQuery("PRAGMA table_info(sellers)");
        print('   - Columnas de sellers: ${columns.map((c) => c['name']).toList()}');
        
      } catch (e) {
        print('❌ Error al acceder a la base de datos: $e');
      }

    } catch (e) {
      print('❌ Error durante debug: $e');
    }
  }

  /// Crear VENDEDOR001 si no existe
  static Future<void> createVendedor001() async {
    print('🔧 === CREANDO VENDEDOR001 ===');
    
    try {
      // Verificar si ya existe
      final existing = await _sellerService.getSellerByIdUnfiltered('VENDEDOR001');
      if (existing != null) {
        print('⚠️ VENDEDOR001 ya existe');
        return;
      }

      // Crear VENDEDOR001
      final vendedor001 = Seller(
        id: 'VENDEDOR001',
        name: 'Vendedor Principal',
        password: '123456',
        isFirstLogin: true,
        createdAt: DateTime.now(),
      );

      await _sellerService.addSeller(vendedor001);
      print('✅ VENDEDOR001 creado exitosamente');

      // Verificar que se creó
      final created = await _sellerService.getSellerById('VENDEDOR001');
      if (created != null) {
        print('✅ VENDEDOR001 verificado en la base de datos');
      } else {
        print('❌ Error: VENDEDOR001 no se pudo verificar');
      }

    } catch (e) {
      print('❌ Error al crear VENDEDOR001: $e');
    }
  }
}
