import '../services/inventory_service.dart';
import '../models/product.dart';

/// Script para probar el guardado y recuperación de productos
Future<void> testProductSaving() async {
  print('🧪 INICIO: Prueba de guardado de productos');
  
  final inventoryService = InventoryService();
  
  try {
    // 1. Verificar productos existentes
    print('\n📋 Paso 1: Obteniendo productos existentes...');
    final existingProducts = await inventoryService.getProducts();
    print('Productos existentes: ${existingProducts.length}');
    
    // 2. Crear un producto de prueba
    print('\n📦 Paso 2: Creando producto de prueba...');
    final testProduct = Product(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Producto de Prueba',
      description: 'Descripción de prueba para verificar guardado',
      wholesalePrice: 100.0,
      retailPrice: 150.0,
      distributionPrice: 200.0,
      quantity: 10,
      category: 'General',
      createdAt: DateTime.now(),
    );
    
    print('Producto creado: ${testProduct.name} (ID: ${testProduct.id})');
    
    // 3. Verificar si el código de barras existe
    print('\n🔍 Paso 3: Verificando código de barras...');
    final barcodeExists = await inventoryService.isBarcodeExists(testProduct.id);
    print('Código de barras existe: $barcodeExists');
    
    // 4. Agregar el producto
    print('\n💾 Paso 4: Agregando producto...');
    await inventoryService.addProduct(testProduct);
    print('✅ Producto agregado exitosamente');
    
    // 5. Verificar que se guardó correctamente
    print('\n🔍 Paso 5: Verificando guardado...');
    final productsAfterAdd = await inventoryService.getProducts();
    print('Productos después de agregar: ${productsAfterAdd.length}');
    
    // 6. Buscar el producto específico
    final foundProduct = productsAfterAdd.firstWhere(
      (p) => p.id == testProduct.id,
      orElse: () => throw Exception('Producto no encontrado'),
    );
    
    print('✅ Producto encontrado: ${foundProduct.name}');
    print('   - Código de barras: ${foundProduct.id}');
    print('   - Precio mayorista: ${foundProduct.wholesalePrice}');
    print('   - Precio retail: ${foundProduct.retailPrice}');
    print('   - Cantidad: ${foundProduct.quantity}');
    print('   - Categoría: ${foundProduct.category}');
    
    // 7. Probar duplicado
    print('\n🚫 Paso 6: Probando código duplicado...');
    try {
      await inventoryService.addProduct(testProduct);
      print('❌ ERROR: Se permitió agregar un producto duplicado');
    } catch (e) {
      print('✅ CORRECTO: Se bloqueó el código duplicado - $e');
    }
    
    print('\n🎉 PRUEBA COMPLETADA: El guardado de productos funciona correctamente');
    
  } catch (e) {
    print('\n❌ ERROR EN LA PRUEBA: $e');
  }
}
