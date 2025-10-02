import 'package:inven_fact/services/seller_service.dart';
import 'package:inven_fact/services/auth_service.dart';
import 'package:inven_fact/models/seller.dart';

class DebugLogin {
  static final SellerService _sellerService = SellerService();
  static final AuthService _authService = AuthService();

  /// Debug del problema de login
  static Future<void> debugLoginIssue() async {
    print('🔍 Debugging login issue...');
    
    try {
      // 1. Verificar todos los vendedores en la base de datos
      print('\n📊 Todos los vendedores en la base de datos:');
      final allSellers = await _sellerService.getAllSellers();
      for (var seller in allSellers) {
        print('ID: ${seller.id}');
        print('Nombre: ${seller.name}');
        print('Contraseña: ${seller.password}');
        print('Primer Login: ${seller.isFirstLogin}');
        print('Activo: ${seller.isActive}');
        print('Último Login: ${seller.lastLogin}');
        print('Creado: ${seller.createdAt}');
        print('─' * 40);
      }

      // 2. Intentar autenticación directa
      print('\n🔐 Probando autenticación directa...');
      final directAuth = await _sellerService.authenticateSeller('RANDY', '123456');
      if (directAuth != null) {
        print('✅ Autenticación directa exitosa');
        print('Vendedor: ${directAuth.name}');
      } else {
        print('❌ Autenticación directa falló');
      }

      // 3. Verificar vendedor específico (sin filtro)
      print('\n🔍 Verificando vendedor RANDY específico (sin filtro)...');
      final randySellerUnfiltered = await _sellerService.getSellerByIdUnfiltered('RANDY');
      if (randySellerUnfiltered != null) {
        print('✅ Vendedor RANDY encontrado (sin filtro)');
        print('Activo: ${randySellerUnfiltered.isActive}');
        print('Contraseña: ${randySellerUnfiltered.password}');
      } else {
        print('❌ Vendedor RANDY no encontrado (sin filtro)');
      }

      // 3b. Verificar vendedor específico (con filtro)
      print('\n🔍 Verificando vendedor RANDY específico (con filtro)...');
      final randySeller = await _sellerService.getSellerById('RANDY');
      if (randySeller != null) {
        print('✅ Vendedor RANDY encontrado (con filtro)');
        print('Activo: ${randySeller.isActive}');
        print('Contraseña: ${randySeller.password}');
      } else {
        print('❌ Vendedor RANDY no encontrado (con filtro) - Probablemente inactivo');
      }

      // 4. Intentar login con AuthService
      print('\n🔐 Probando login con AuthService...');
      final authSuccess = await _authService.loginSeller('RANDY', '123456');
      if (authSuccess) {
        print('✅ Login con AuthService exitoso');
      } else {
        print('❌ Login con AuthService falló');
      }

    } catch (e) {
      print('❌ Error durante debug: $e');
    }
  }

  /// Arreglar vendedor RANDY si está inactivo
  static Future<void> fixRandySeller() async {
    print('🔧 Arreglando vendedor RANDY...');
    
    try {
      final randySeller = await _sellerService.getSellerByIdUnfiltered('RANDY');
      if (randySeller != null) {
        // Activar el vendedor si está inactivo
        final updatedSeller = randySeller.copyWith(isActive: true);
        await _sellerService.updateSeller(updatedSeller);
        print('✅ Vendedor RANDY activado');
        print('Estado actual: Activo = ${updatedSeller.isActive}');
      } else {
        print('❌ Vendedor RANDY no encontrado');
        // Crear el vendedor si no existe
        await createRandySeller();
      }
    } catch (e) {
      print('❌ Error al arreglar vendedor: $e');
    }
  }

  /// Crear vendedor RANDY si no existe
  static Future<void> createRandySeller() async {
    print('👤 Creando vendedor RANDY...');
    
    try {
      final randySeller = Seller(
        id: 'RANDY',
        name: 'RANDY',
        password: '123456',
        isFirstLogin: false,
        createdAt: DateTime.now(),
        isActive: true,
      );
      
      await _sellerService.addSeller(randySeller);
      print('✅ Vendedor RANDY creado exitosamente');
    } catch (e) {
      print('❌ Error al crear vendedor: $e');
    }
  }
}
