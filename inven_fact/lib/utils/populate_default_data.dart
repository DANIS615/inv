import 'package:inven_fact/services/client_service.dart';
import 'package:inven_fact/services/inventory_service.dart';
import 'package:inven_fact/services/seller_service.dart';
import 'package:inven_fact/models/client.dart';
import 'package:inven_fact/models/product.dart';
import 'package:inven_fact/models/seller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'database_helper.dart';

class PopulateDefaultData {
  static final ClientService _clientService = ClientService();
  static final InventoryService _inventoryService = InventoryService();
  static final SellerService _sellerService = SellerService();

  /// Poblar la aplicación con datos de ejemplo para desarrollo
  static Future<void> populateAllData() async {
    try {
      // 1. Configurar datos de empresa
      await _setupCompanyData();
      
      // 2. Crear vendedores de ejemplo
      await _createSampleSellers();
      
      // 3. Crear clientes de ejemplo
      await _createSampleClients();
      
      // 4. Crear productos de ejemplo
      await _createSampleProducts();
      
      print('✅ Datos por defecto poblados exitosamente');
    } catch (e) {
      print('❌ Error al poblar datos: $e');
      rethrow;
    }
  }

  /// Configurar datos de la empresa
  static Future<void> _setupCompanyData() async {
    final prefs = await SharedPreferences.getInstance();
    
    await prefs.setString('companyName', 'InvenFact Demo');
    await prefs.setString('companyAddress', 'Av. Principal #123, Santo Domingo');
    await prefs.setString('companyPhone', '809-555-0123');
    await prefs.setString('companyRNC', '12345678901');
    await prefs.setString('branch', 'Sucursal Principal');
    
    print('✅ Datos de empresa configurados');
  }

  /// Crear vendedores de ejemplo
  static Future<void> _createSampleSellers() async {
    final sellers = [
      Seller(
        id: '2',
        name: 'Juan Pérez',
        password: '123456', // En producción esto debería estar hasheado
        isFirstLogin: false,
        createdAt: DateTime.now(),
      ),
      Seller(
        id: '3',
        name: 'María García',
        password: '123456',
        isFirstLogin: false,
        createdAt: DateTime.now(),
      ),
    ];

    for (final seller in sellers) {
      try {
        await _sellerService.addSeller(seller);
        print('✅ Vendedor creado: ${seller.name}');
      } catch (e) {
        print('⚠️ Vendedor ya existe: ${seller.name}');
      }
    }
  }

  /// Crear clientes de ejemplo
  static Future<void> _createSampleClients() async {
    final clients = [
      Client(
        id: 1,
        name: 'Carlos Rodríguez',
        code: 'CLI001',
        email: 'carlos@email.com',
        telefono: '809-123-4567',
        direccion: 'Calle 1ra #45, Santiago',
        accountType: AccountType.credito,
      ),
      Client(
        id: 2,
        name: 'Ana López',
        code: 'CLI002',
        email: 'ana@email.com',
        telefono: '809-234-5678',
        direccion: 'Av. 27 de Febrero #78, Santo Domingo',
        accountType: AccountType.contado,
      ),
      Client(
        id: 3,
        name: 'Roberto Martínez',
        code: 'CLI003',
        email: 'roberto@email.com',
        telefono: '809-345-6789',
        direccion: 'Calle Duarte #12, La Vega',
        accountType: AccountType.credito,
        pendingBalance: 5000.0,
      ),
      Client(
        id: 4,
        name: 'Laura Sánchez',
        code: 'CLI004',
        email: 'laura@email.com',
        telefono: '809-456-7890',
        direccion: 'Av. Independencia #90, Puerto Plata',
        accountType: AccountType.contado,
      ),
    ];

    for (final client in clients) {
      try {
        await _clientService.addClient(client);
        print('✅ Cliente creado: ${client.name}');
      } catch (e) {
        print('⚠️ Cliente ya existe: ${client.name}');
      }
    }
  }

  /// Crear productos de ejemplo
  static Future<void> _createSampleProducts() async {
    final products = [
      Product(
        id: '1',
        name: 'Arroz Extra',
        description: 'Arroz de grano largo, 1kg',
        wholesalePrice: 45.0,
        retailPrice: 55.0,
        distributionPrice: 40.0,
        quantity: 100,
        category: 'Alimentos',
        createdAt: DateTime.now(),
        barcode: '1234567890123',
      ),
      Product(
        id: '2',
        name: 'Aceite de Cocina',
        description: 'Aceite vegetal, 1 litro',
        wholesalePrice: 85.0,
        retailPrice: 95.0,
        distributionPrice: 80.0,
        quantity: 50,
        category: 'Alimentos',
        createdAt: DateTime.now(),
        barcode: '2345678901234',
      ),
      Product(
        id: '3',
        name: 'Leche Entera',
        description: 'Leche pasteurizada, 1 litro',
        wholesalePrice: 35.0,
        retailPrice: 42.0,
        distributionPrice: 32.0,
        quantity: 75,
        category: 'Lácteos',
        createdAt: DateTime.now(),
        barcode: '3456789012345',
      ),
      Product(
        id: '4',
        name: 'Pan Integral',
        description: 'Pan de trigo integral, 500g',
        wholesalePrice: 25.0,
        retailPrice: 30.0,
        distributionPrice: 22.0,
        quantity: 60,
        category: 'Panadería',
        createdAt: DateTime.now(),
        barcode: '4567890123456',
      ),
      Product(
        id: '5',
        name: 'Huevos Frescos',
        description: 'Huevos de gallina, docena',
        wholesalePrice: 60.0,
        retailPrice: 70.0,
        distributionPrice: 55.0,
        quantity: 40,
        category: 'Proteínas',
        createdAt: DateTime.now(),
        barcode: '5678901234567',
      ),
      Product(
        id: '6',
        name: 'Pollo Entero',
        description: 'Pollo fresco, 1.5kg aprox',
        wholesalePrice: 120.0,
        retailPrice: 140.0,
        distributionPrice: 110.0,
        quantity: 25,
        category: 'Carnes',
        createdAt: DateTime.now(),
        barcode: '6789012345678',
      ),
      Product(
        id: '7',
        name: 'Coca Cola',
        description: 'Refresco de cola, 2 litros',
        wholesalePrice: 45.0,
        retailPrice: 55.0,
        distributionPrice: 40.0,
        quantity: 80,
        category: 'Bebidas',
        createdAt: DateTime.now(),
        barcode: '7890123456789',
      ),
      Product(
        id: '8',
        name: 'Agua Purificada',
        description: 'Agua purificada, 5 galones',
        wholesalePrice: 80.0,
        retailPrice: 95.0,
        distributionPrice: 75.0,
        quantity: 30,
        category: 'Bebidas',
        createdAt: DateTime.now(),
        barcode: '8901234567890',
      ),
      Product(
        id: '9',
        name: 'Detergente Líquido',
        description: 'Detergente para ropa, 1 litro',
        wholesalePrice: 65.0,
        retailPrice: 75.0,
        distributionPrice: 60.0,
        quantity: 45,
        category: 'Limpieza',
        createdAt: DateTime.now(),
        barcode: '9012345678901',
      ),
      Product(
        id: '10',
        name: 'Papel Higiénico',
        description: 'Papel higiénico, 4 rollos',
        wholesalePrice: 35.0,
        retailPrice: 42.0,
        distributionPrice: 32.0,
        quantity: 90,
        category: 'Higiene',
        createdAt: DateTime.now(),
        barcode: '0123456789012',
      ),
    ];

    for (final product in products) {
      try {
        await _inventoryService.addProduct(product);
        print('✅ Producto creado: ${product.name}');
      } catch (e) {
        print('⚠️ Producto ya existe: ${product.name}');
      }
    }
  }

  /// Limpiar TODOS los datos y dejar solo VENDEDOR001
  static Future<void> clearAllData() async {
    try {
      print('🔧 === INICIANDO RESET COMPLETO ===');
      
      // 1. Limpiar SharedPreferences (esto funciona siempre)
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ SharedPreferences limpiado');
      
      // 2. Limpiar productos usando InventoryService (funciona con SharedPreferences)
      try {
        await _clearAllProducts();
        print('✅ Productos eliminados');
      } catch (e) {
        print('⚠️ Error al limpiar productos: $e');
      }
      
      // 3. Eliminar base de datos corrupta y crear nueva
      try {
        await _recreateDatabase();
        print('✅ Base de datos recreada');
      } catch (e) {
        print('⚠️ Error al recrear base de datos: $e');
      }
      
      // 4. Configurar solo VENDEDOR001 en SharedPreferences
      await prefs.setString('current_seller_id', 'VENDEDOR001');
      await prefs.setString('current_seller_name', 'Vendedor Principal');
      await prefs.setString('current_seller_password', '123456');
      await prefs.setBool('isFirstLogin', true);
      
      print('✅ VENDEDOR001 configurado como vendedor por defecto');
      print('✅ isFirstLogin establecido en true');
      print('✅ Proceso de limpieza completado');
      print('ℹ️ Reinicia la app para que se apliquen todos los cambios');
      
    } catch (e) {
      print('❌ Error general al limpiar datos: $e');
      rethrow;
    }
  }

  /// Recrear base de datos desde cero
  static Future<void> _recreateDatabase() async {
    try {
      // Usar DatabaseHelper directamente
      await DatabaseHelper.clearDatabase();
      await DatabaseHelper.initializeDatabase();
      print('✅ Base de datos recreada exitosamente');
    } catch (e) {
      print('⚠️ Error al recrear base de datos: $e');
      // Continuar sin fallar
    }
  }

  /// Limpiar solo SharedPreferences (función segura)
  static Future<void> clearSharedPreferencesOnly() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Configurar VENDEDOR001
      await prefs.setString('current_seller_id', '1');
      await prefs.setString('current_seller_name', 'VENDEDOR001');
      await prefs.setString('current_seller_password', '123456');
      await prefs.setBool('isFirstLogin', true);
      
      print('✅ SharedPreferences limpiado completamente');
      print('✅ VENDEDOR001 configurado');
      print('✅ isFirstLogin = true');
      print('ℹ️ Reinicia la app para aplicar cambios');
      
    } catch (e) {
      print('❌ Error al limpiar SharedPreferences: $e');
      rethrow;
    }
  }

  /// Limpiar todos los clientes
  static Future<void> _clearAllClients() async {
    try {
      // Obtener todos los clientes
      final clients = await _clientService.getClients();
      
      // Eliminar cada cliente
      for (final client in clients) {
        await _clientService.deleteClient(client.id!);
        print('🗑️ Cliente eliminado: ${client.name}');
      }
      
      print('✅ Todos los clientes eliminados');
    } catch (e) {
      print('⚠️ Error al limpiar clientes: $e');
    }
  }

  /// Limpiar todos los productos
  static Future<void> _clearAllProducts() async {
    try {
      // Obtener todos los productos
      final products = await _inventoryService.getProducts();
      
      // Eliminar cada producto
      for (final product in products) {
        await _inventoryService.deleteProduct(product.id);
        print('🗑️ Producto eliminado: ${product.name}');
      }
      
      print('✅ Todos los productos eliminados');
    } catch (e) {
      print('⚠️ Error al limpiar productos: $e');
    }
  }

  /// Limpiar todos los vendedores
  static Future<void> _clearAllSellers() async {
    try {
      // Obtener todos los vendedores
      final sellers = await _sellerService.getSellers();
      
      // Eliminar cada vendedor
      for (final seller in sellers) {
        await _sellerService.deleteSeller(seller.id);
        print('🗑️ Vendedor eliminado: ${seller.name}');
      }
      
      print('✅ Todos los vendedores eliminados');
    } catch (e) {
      print('⚠️ Error al limpiar vendedores: $e');
    }
  }

  /// Crear solo VENDEDOR001 por defecto
  static Future<void> _createDefaultSeller() async {
    try {
      final defaultSeller = Seller(
        id: '1',
        name: 'VENDEDOR001',
        password: '123456',
        isFirstLogin: true, // Para que aparezca la pantalla de configuración
        createdAt: DateTime.now(),
      );

      await _sellerService.addSeller(defaultSeller);
      print('✅ VENDEDOR001 creado (primer login: true)');
    } catch (e) {
      print('❌ Error al crear VENDEDOR001: $e');
      rethrow;
    }
  }

  /// Verificar si ya existen datos
  static Future<bool> hasData() async {
    try {
      final clients = await _clientService.getClients();
      final products = await _inventoryService.getProducts();
      return clients.isNotEmpty || products.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
}
