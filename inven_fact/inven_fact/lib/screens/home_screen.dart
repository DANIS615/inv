import 'dart:io';
import 'package:flutter/material.dart';
import 'package:inven_fact/config/theme.dart';
import 'package:inven_fact/screens/clients_screen.dart';
import 'package:inven_fact/screens/company_screen.dart';
import 'package:inven_fact/screens/company_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../services/client_context_service.dart';
import 'add_product_screen.dart';
import '../utils/event_bus.dart';
import 'product_detail_screen.dart';
import 'invoice_screen.dart';

class HomeScreen extends StatefulWidget {
  final String clientCode;
  
  const HomeScreen({super.key, required this.clientCode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ClientContextService _clientContext = ClientContextService();
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = true;
  bool _isSelectionMode = false;
  final List<Product> _selectedProducts = [];
  final TextEditingController _searchController = TextEditingController();

  String _companyName = 'Nombre de Empresa';
  String _companyEmail = 'info@empresa.com';

  @override
  void initState() {
    super.initState();
    _initializeClient();
    _searchController.addListener(_filterProducts);
  }

  Future<void> _initializeClient() async {
    try {
      // Asegurar que el contexto del cliente está establecido
      await _clientContext.setCurrentClient(widget.clientCode);
      await _loadProducts();
      await _loadCompanyInfo();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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

    final products = await _inventoryService.getProducts();
    setState(() {
      _products = products;
      _filteredProducts = products;
      _isLoading = false;
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  Future<void> _loadCompanyInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _companyName = prefs.getString('companyName') ?? 'Nombre de Empresa';
      _companyEmail = prefs.getString('companyEmail') ?? 'info@empresa.com';
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        return product.name.toLowerCase().contains(query) ||
            product.category.toLowerCase().contains(query);
      }).toList();
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
        title: const Text('Inventario'),
        actions: [
          if (_products.isNotEmpty)
            TextButton(
              onPressed: _toggleSelectionMode,
              child: Text(
                _isSelectionMode ? 'Cancelar' : 'Seleccionar',
                style: theme.textTheme.labelLarge?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
      drawer: _buildDrawer(context, theme),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: Column(
          children: [
            _buildSearchField(theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredProducts.isEmpty
                      ? _buildEmptyState(theme)
                      : _buildProductGrid(theme),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Buscar productos...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
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
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 24),
          Text(
            _searchController.text.isEmpty
                ? 'No hay productos'
                : 'No se encontraron productos',
            style: theme.textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Agrega tu primer producto para empezar'
                : 'Intenta con otra búsqueda',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductGrid(ThemeData theme) {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (context, index) {
        final product = _filteredProducts[index];
        final isSelected = _selectedProducts.contains(product);
        return _buildProductCard(product, isSelected, theme);
      },
    );
  }

  Widget _buildProductCard(Product product, bool isSelected, ThemeData theme) {
    return GestureDetector(
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
      child: Card(
        elevation: isSelected ? 8 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.file(
                            File(product.imageUrl!),
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: theme.primaryColor.withOpacity(0.1),
                            child: Icon(
                              _getCategoryIcon(product.category),
                              size: 48,
                              color: theme.primaryColor,
                            ),
                          ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.retailPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.inventory,
                            size: 14,
                            color: product.quantity > 0
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Cant: ${product.quantity}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: product.quantity > 0
                                  ? AppTheme.successColor
                                  : AppTheme.errorColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (_isSelectionMode)
              Positioned(
                top: 8,
                right: 8,
                child: Checkbox(
                  value: isSelected,
                  onChanged: (bool? value) {
                    _onProductSelected(product);
                  },
                  activeColor: theme.colorScheme.primary,
                  shape: const CircleBorder(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_isSelectionMode && _selectedProducts.isNotEmpty)
          FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      InvoiceScreen(products: _selectedProducts),
                ),
              );
              _loadProducts();
            },
            label: Text('Facturar (${_selectedProducts.length})'),
            icon: const Icon(Icons.receipt_long),
            heroTag: 'invoice',
          ),
        if (!_isSelectionMode)
          FloatingActionButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddProductScreen(),
                ),
              );
              try { EventBus().fire('inventoryChanged'); } catch (_) {}
              _loadProducts();
            },
            child: const Icon(Icons.add),
            heroTag: 'add',
          ),
      ],
    );
  }

  Drawer _buildDrawer(BuildContext context, ThemeData theme) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          UserAccountsDrawerHeader(
            accountName: Text(_companyName, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            accountEmail: Text('Cliente: ${widget.clientCode}\n$_companyEmail'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                _companyName.isNotEmpty ? _companyName[0].toUpperCase() : 'I',
                style: TextStyle(fontSize: 40.0, color: theme.primaryColor),
              ),
            ),
            decoration: BoxDecoration(
              color: theme.primaryColor,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home_outlined),
            title: const Text('Inicio'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.business_outlined),
            title: const Text('Mi Empresa'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CompanySettingsScreen()),
              );
              _loadCompanyInfo(); // Reload company info after returning from settings
            },
          ),
          ListTile(
            leading: const Icon(Icons.people_alt_outlined),
            title: const Text('Mis Clientes'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ClientsScreen()),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings_outlined),
            title: const Text('Configuración'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings screen
            },
          ),
        ],
      ),
    );
  }
}
