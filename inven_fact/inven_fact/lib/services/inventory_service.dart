import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import 'client_context_service.dart';
import '../utils/event_bus.dart';

class InventoryService {
  static const String _baseStorageKey = 'inventory_products';
  final ClientContextService _clientContext = ClientContextService();

  Future<List<Product>> getProducts() async {
    // Usar clave general para vendedores (no depender del contexto de cliente)
    final prefs = await SharedPreferences.getInstance();
    final storageKey = '${_baseStorageKey}_general';
    print('🔍 DEBUG InventoryService: Obteniendo productos con clave: $storageKey');
    final String? productsJson = prefs.getString(storageKey);

    if (productsJson == null) {
      print('🔍 DEBUG InventoryService: No hay productos guardados');
      return [];
    }

    final List<dynamic> productsList = json.decode(productsJson);
    final products = productsList.map((json) => Product.fromJson(json)).toList();
    
    // Migrar productos existentes que no tienen código de barras
    bool needsMigration = false;
    final migratedProducts = products.map((product) {
      if (product.barcode == null || product.barcode!.isEmpty) {
        needsMigration = true;
        return product.copyWith(barcode: product.id); // Usar el ID como código de barras
      }
      return product;
    }).toList();
    
    if (needsMigration) {
      print('🔍 DEBUG InventoryService: Migrando productos sin código de barras');
      await saveProducts(migratedProducts);
    }
    
    print('🔍 DEBUG InventoryService: Productos encontrados: ${migratedProducts.length}');
    return migratedProducts;
  }

  Future<void> saveProducts(List<Product> products) async {
    // Usar clave general para vendedores (no depender del contexto de cliente)
    final prefs = await SharedPreferences.getInstance();
    final storageKey = '${_baseStorageKey}_general';
    final String productsJson = json.encode(
      products.map((product) => product.toJson()).toList(),
    );
    await prefs.setString(storageKey, productsJson);
  }

  Future<bool> isBarcodeExists(String barcode) async {
    final products = await getProducts();
    return products.any((product) => product.barcode == barcode);
  }

  Future<void> addProduct(Product product) async {
    print('🔍 DEBUG InventoryService: Agregando producto: ${product.name}');
    print('🔍 DEBUG InventoryService: Código de barras: ${product.barcode}');
    
    // Verificar si el código de barras ya existe
    if (product.barcode != null && product.barcode!.isNotEmpty) {
      final barcodeExists = await isBarcodeExists(product.barcode!);
      if (barcodeExists) {
        throw Exception('El código de barras "${product.barcode}" ya está registrado. Por favor, usa un código diferente.');
      }
    }
    
    final products = await getProducts();
    print('🔍 DEBUG InventoryService: Productos actuales: ${products.length}');
    products.add(product);
    print('🔍 DEBUG InventoryService: Productos después de agregar: ${products.length}');
    await saveProducts(products);
    print('🔍 DEBUG InventoryService: Productos guardados exitosamente');
    
    // Emitir evento para actualizar dashboard
    try {
      EventBus().fire('productAdded');
      EventBus().fire('inventoryChanged');
      print('🔔 DEBUG InventoryService: Eventos emitidos: productAdded, inventoryChanged');
    } catch (e) {
      print('❌ ERROR InventoryService: Error al emitir eventos: $e');
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final products = await getProducts();
    final index = products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      // Si el producto existe, verificar si el código de barras cambió
      final originalProduct = products[index];
      if (originalProduct.barcode != updatedProduct.barcode) {
        // El código de barras cambió, verificar si el nuevo código ya existe
        if (updatedProduct.barcode != null && updatedProduct.barcode!.isNotEmpty) {
          final barcodeExists = await isBarcodeExists(updatedProduct.barcode!);
          if (barcodeExists) {
            throw Exception('El código de barras "${updatedProduct.barcode}" ya está registrado. Por favor, usa un código diferente.');
          }
        }
      }
      products[index] = updatedProduct;
      await saveProducts(products);
      
      // Emitir evento para actualizar dashboard
      try {
        EventBus().fire('productUpdated');
        EventBus().fire('inventoryChanged');
        print('🔔 DEBUG InventoryService: Eventos emitidos: productUpdated, inventoryChanged');
      } catch (e) {
        print('❌ ERROR InventoryService: Error al emitir eventos: $e');
      }
    }
  }

  Future<void> deleteProduct(String productId) async {
    final products = await getProducts();
    final initialLength = products.length;
    products.removeWhere((p) => p.id == productId);
    await saveProducts(products);
    
    // Emitir evento para actualizar dashboard solo si se eliminó algo
    if (products.length < initialLength) {
      try {
        EventBus().fire('productDeleted');
        EventBus().fire('inventoryChanged');
        print('🔔 DEBUG InventoryService: Eventos emitidos: productDeleted, inventoryChanged');
      } catch (e) {
        print('❌ ERROR InventoryService: Error al emitir eventos: $e');
      }
    }
  }
}
