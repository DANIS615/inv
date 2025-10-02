import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inven_fact/config/theme.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import 'add_product_screen.dart';
import 'product_detail_screen.dart';
import 'invoice_screen.dart';

class InventoryDashboardScreen extends StatefulWidget {
  final bool showLowStock;
  final bool showOutOfStock;
  const InventoryDashboardScreen({super.key, this.showLowStock = false, this.showOutOfStock = false});

  @override
  State<InventoryDashboardScreen> createState() => _InventoryDashboardScreenState();
}

class _InventoryDashboardScreenState extends State<InventoryDashboardScreen> {
  final InventoryService _inventoryService = InventoryService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final List<Product> _selectedProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Todas';
  String _sortBy = 'nombre';

  // Lista de categorías
  final List<String> _categories = [
    'Todas',
    'General',
    'Electrónicos',
    'Ropa',
    'Comida',
    'Hogar',
    'Deportes',
    'Libros',
    'Juguetes',
    'Herramientas',
    'Belleza',
    'Automóvil',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadProducts();
    // Aplicar filtros iniciales si vienen desde dashboard
    if (widget.showLowStock == true) {
      _selectedCategory = 'Todas';
      // Mantener lógica en _filterProducts leyendo cantidades
    }
    if (widget.showOutOfStock == true) {
      _selectedCategory = 'Todas';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final products = await _inventoryService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
        _isSelectionMode = false;
        _selectedProducts.clear();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar productos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query) ||
            product.description.toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'Todas' || 
            product.category == _selectedCategory;
        final matchesLow = (widget.showLowStock != true) || product.quantity < 10;
        final matchesOut = (widget.showOutOfStock != true) || product.quantity == 0;
        return matchesSearch && matchesCategory && matchesLow && matchesOut;
      }).toList();
      
      _sortProducts();
    });
  }

  void _sortProducts() {
    _filteredProducts.sort((a, b) {
      switch (_sortBy) {
        case 'nombre':
          return a.name.compareTo(b.name);
        case 'precio':
          return a.retailPrice.compareTo(b.retailPrice);
        case 'cantidad':
          return b.quantity.compareTo(a.quantity);
        case 'categoria':
          return a.category.compareTo(b.category);
        default:
          return 0;
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedProducts.clear();
      }
    });
  }

  void _onProductSelected(Product product) {
    setState(() {
      if (_selectedProducts.contains(product)) {
        _selectedProducts.remove(product);
      } else {
        _selectedProducts.add(product);
      }
    });
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electrónicos':
      case 'electronicos':
        return Icons.devices;
      case 'ropa':
      case 'vestimenta':
        return Icons.checkroom;
      case 'comida':
      case 'alimentos':
        return Icons.restaurant;
      case 'hogar':
      case 'casa':
        return Icons.home;
      case 'deportes':
        return Icons.sports;
      case 'libros':
        return Icons.book;
      case 'juguetes':
        return Icons.toys;
      case 'herramientas':
        return Icons.build;
      case 'belleza':
      case 'cosméticos':
        return Icons.face;
      case 'automóvil':
      case 'auto':
        return Icons.directions_car;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Inventario'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (_products.isNotEmpty)
            IconButton(
              onPressed: _toggleSelectionMode,
              icon: Icon(_isSelectionMode ? Icons.close : Icons.checklist),
              tooltip: _isSelectionMode ? 'Cancelar Selección' : 'Seleccionar Productos',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros y búsqueda
          _buildFiltersAndSearch(theme),
          
          // Estadísticas rápidas
          _buildQuickStats(theme),
          
          // Lista de productos
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadProducts,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildProductList(theme),
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildFiltersAndSearch(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Column(
        children: [
          // Barra de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar productos...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtros
          LayoutBuilder(
            builder: (context, constraints) {
              // Si el ancho es muy pequeño, usar layout vertical
              if (constraints.maxWidth < 400) {
                return Column(
                  children: [
                    // Filtro por categoría
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Categoría',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem(
                          value: category,
                          child: Text(
                            category,
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _filterProducts();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    // Ordenar por
                    DropdownButtonFormField<String>(
                      value: _sortBy,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Ordenar',
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                        DropdownMenuItem(value: 'precio', child: Text('Precio')),
                        DropdownMenuItem(value: 'cantidad', child: Text('Cantidad')),
                        DropdownMenuItem(value: 'categoria', child: Text('Categoría')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _sortBy = value!;
                          _sortProducts();
                        });
                      },
                    ),
                  ],
                );
              } else {
                // Layout horizontal para pantallas más grandes
                return Row(
                  children: [
                    // Filtro por categoría
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Categoría',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCategory = value!;
                            _filterProducts();
                          });
                        },
                      ),
                    ),
                    
                    const SizedBox(width: 6),
                    
                    // Ordenar por
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _sortBy,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Ordenar',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'nombre', child: Text('Nombre')),
                          DropdownMenuItem(value: 'precio', child: Text('Precio')),
                          DropdownMenuItem(value: 'cantidad', child: Text('Cantidad')),
                          DropdownMenuItem(value: 'categoria', child: Text('Categoría')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _sortBy = value!;
                            _sortProducts();
                          });
                        },
                      ),
                    ),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    final totalProducts = _products.length;
    final lowStockProducts = _products.where((p) => p.quantity < 10).length;
    final outOfStockProducts = _products.where((p) => p.quantity == 0).length;
    final totalValue = _products.fold(0.0, (sum, p) => sum + (p.retailPrice * p.quantity));

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Total Productos',
              totalProducts.toString(),
              Icons.inventory_2,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Bajo Stock',
              lowStockProducts.toString(),
              Icons.warning,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Sin Stock',
              outOfStockProducts.toString(),
              Icons.error,
              Colors.red,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildStatCard(
              'Valor Total',
              'RD\$${totalValue.toStringAsFixed(0)}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 10,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay productos en el inventario'
                : 'No se encontraron productos',
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Agrega tu primer producto para empezar'
                : 'Intenta con otra búsqueda o filtro',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
              _loadProducts();
            },
            icon: const Icon(Icons.add),
            label: const Text('Agregar Producto'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isSelected = _selectedProducts.contains(product);
        return _buildProductCard(product, isSelected, theme);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSelected, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? theme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: () async {
          if (_isSelectionMode) {
            _onProductSelected(product);
          } else {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
            _loadProducts();
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _onProductSelected(product);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Imagen del producto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: theme.primaryColor.withOpacity(0.1),
                ),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(product.imageUrl!),
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        _getCategoryIcon(product.category),
                        size: 30,
                        color: theme.primaryColor,
                      ),
              ),
              
              const SizedBox(width: 16),
              
              // Información del producto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Flexible(
                          flex: 2,
                          child: Text(
                            'RD\$${product.retailPrice.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 1,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.quantity > 10
                                  ? Colors.green[100]
                                  : product.quantity > 0
                                      ? Colors.orange[100]
                                      : Colors.red[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Stock: ${product.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: product.quantity > 10
                                    ? Colors.green[700]
                                    : product.quantity > 0
                                        ? Colors.orange[700]
                                        : Colors.red[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Checkbox de selección o menú contextual
              if (_isSelectionMode)
                Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _onProductSelected(product);
                  },
                  activeColor: theme.primaryColor,
                )
              else
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _showDeleteProductDialog(product);
                    } else if (value == 'edit') {
                      _editProduct(product);
                    }
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: Colors.blue),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Eliminar'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isSelectionMode && _selectedProducts.isNotEmpty)
          FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvoiceScreen(),
                ),
              );
              _loadProducts();
            },
            label: Text('Facturar (${_selectedProducts.length})'),
            icon: const Icon(Icons.receipt_long),
            heroTag: 'invoice',
            backgroundColor: Colors.green,
          ),
        const SizedBox(height: 16),
        FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddProductScreen(),
              ),
            );
            _loadProducts();
          },
          child: const Icon(Icons.add),
          heroTag: 'add',
        ),
      ],
    );
  }

  void _showDeleteProductDialog(Product product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Producto'),
          content: Text('¿Estás seguro de que quieres eliminar "${product.name}"?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProduct(product);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      await _inventoryService.deleteProduct(product.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Producto "${product.name}" eliminado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        _loadProducts();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar producto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editProduct(Product product) async {
    // Navegar a la pantalla de edición de producto
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
    _loadProducts();
  }
}
