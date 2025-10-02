import '../services/inventory_service.dart';
import '../models/product.dart';

class TestProductSavingFix {
  static final InventoryService _inventoryService = InventoryService();

  /// Probar el guardado de productos
  static Future<void> testProductSaving() async {
    print('🔍 === PROBANDO GUARDADO DE PRODUCTOS ===');
    
    try {
      // 1. Verificar productos existentes
      print('\n📊 Productos existentes:');
      final existingProducts = await _inventoryService.getProducts();
      print('   - Total: ${existingProducts.length}');
      
      for (var product in existingProducts) {
        print('   - ${product.name} (${product.barcode})');
      }

      // 2. Crear un producto de prueba
      print('\n🔧 Creando producto de prueba...');
      final testProduct = Product(
        id: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Producto de Prueba',
        description: 'Producto creado para probar el guardado',
        wholesalePrice: 100.0,
        retailPrice: 150.0,
        distributionPrice: 120.0,
        quantity: 10,
        category: 'General',
        createdAt: DateTime.now(),
        barcode: 'TEST_${DateTime.now().millisecondsSinceEpoch}',
      );

      // 3. Guardar el producto
      print('💾 Guardando producto...');
      await _inventoryService.addProduct(testProduct);
      print('✅ Producto guardado exitosamente');

      // 4. Verificar que se guardó
      print('\n🔍 Verificando guardado...');
      final productsAfter = await _inventoryService.getProducts();
      print('   - Total después: ${productsAfter.length}');
      
      final savedProduct = productsAfter.firstWhere(
        (p) => p.id == testProduct.id,
        orElse: () => throw Exception('Producto no encontrado'),
      );
      
      print('✅ Producto encontrado: ${savedProduct.name}');
      print('✅ Código de barras: ${savedProduct.barcode}');
      print('✅ Cantidad: ${savedProduct.quantity}');

      // 5. Limpiar producto de prueba
      print('\n🧹 Limpiando producto de prueba...');
      await _inventoryService.deleteProduct(testProduct.id);
      print('✅ Producto de prueba eliminado');

      print('\n🎉 Prueba de guardado exitosa');

    } catch (e) {
      print('❌ Error en la prueba: $e');
      rethrow;
    }
  }
}
