import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/invoice.dart';
import '../services/inventory_service.dart';
import '../services/invoice_service.dart';

class InvoiceScreen extends StatefulWidget {
  const InvoiceScreen({super.key});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();
  final _invoiceService = InvoiceService();
  
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  
  List<Product> _products = [];
  List<InvoiceItem> _invoiceItems = [];
  bool _isLoading = true;
  String _selectedPriceType = 'retail';
  double _taxRate = 0.16; // 16% IVA
  
  @override
  void initState() {
    super.initState();
    _loadProducts();
  }
  
  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    super.dispose();
  }
  
  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
    });
    
    final products = await _inventoryService.getProducts();
    setState(() {
      _products = products;
      _isLoading = false;
    });
  }
  
  double _getProductPrice(Product product, String priceType) {
    switch (priceType) {
      case 'wholesale':
        return product.wholesalePrice;
      case 'distribution':
        return product.distributionPrice;
      case 'retail':
      default:
        return product.retailPrice;
    }
  }
  
  String _getPriceTypeLabel(String priceType) {
    switch (priceType) {
      case 'wholesale':
        return 'Mayoreo';
      case 'distribution':
        return 'Distribución';
      case 'retail':
      default:
        return 'Detalle';
    }
  }
  
  void _addProductToInvoice(Product product, int quantity) {
    final unitPrice = _getProductPrice(product, _selectedPriceType);
    
    final existingItemIndex = _invoiceItems.indexWhere(
      (item) => item.productId == product.id && item.priceType == _selectedPriceType,
    );
    
    setState(() {
      if (existingItemIndex >= 0) {
        // Actualizar cantidad si el producto ya existe
        final existingItem = _invoiceItems[existingItemIndex];
        _invoiceItems[existingItemIndex] = InvoiceItem(
          productId: product.id,
          productName: product.name,
          quantity: existingItem.quantity + quantity,
          unitPrice: unitPrice,
          priceType: _selectedPriceType,
        );
      } else {
        // Agregar nuevo item
        _invoiceItems.add(InvoiceItem(
          productId: product.id,
          productName: product.name,
          quantity: quantity,
          unitPrice: unitPrice,
          priceType: _selectedPriceType,
        ));
      }
    });
  }
  
  void _removeItemFromInvoice(int index) {
    setState(() {
      _invoiceItems.removeAt(index);
    });
  }
  
  double get _subtotal {
    return _invoiceItems.fold(0.0, (sum, item) => sum + item.total);
  }
  
  double get _tax {
    return _subtotal * _taxRate;
  }
  
  double get _total {
    return _subtotal + _tax;
  }
  
  Future<void> _saveInvoice() async {
    if (!_formKey.currentState!.validate() || _invoiceItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos y agrega al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final invoice = Invoice(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      customerName: _customerNameController.text.trim(),
      customerEmail: _customerEmailController.text.trim(),
      createdAt: DateTime.now(),
      items: _invoiceItems,
      subtotal: _subtotal,
      tax: _tax,
      total: _total,
    );
    
    try {
      await _invoiceService.saveInvoice(invoice);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura guardada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Limpiar formulario
        _customerNameController.clear();
        _customerEmailController.clear();
        setState(() {
          _invoiceItems.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar la factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Factura'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Información del cliente
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Información del Cliente',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _customerNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nombre del Cliente *',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.person),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'El nombre del cliente es requerido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _customerEmailController,
                                  decoration: const InputDecoration(
                                    labelText: 'Email del Cliente',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.email),
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                        return 'Ingresa un email válido';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Selector de tipo de precio
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tipo de Precio',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedPriceType,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.attach_money),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'retail',
                                      child: Text('Precio al Detalle'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'wholesale',
                                      child: Text('Precio al Mayoreo'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'distribution',
                                      child: Text('Precio de Distribución'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPriceType = value!;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Lista de productos disponibles
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Productos Disponibles',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ..._products.map((product) => _buildProductTile(product)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Items de la factura
                        if (_invoiceItems.isNotEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Items de la Factura',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ..._invoiceItems.asMap().entries.map(
                                    (entry) => _buildInvoiceItem(entry.key, entry.value),
                                  ),
                                  const Divider(),
                                  _buildTotals(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ],
                    ),
                  ),
                  
                  // Botón para guardar factura
                  if (_invoiceItems.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _saveInvoice,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text(
                          'Guardar Factura',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  Widget _buildProductTile(Product product) {
    final price = _getProductPrice(product, _selectedPriceType);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor,
          child: Icon(
            _getCategoryIcon(product.category),
            color: Colors.white,
          ),
        ),
        title: Text(product.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Categoría: ${product.category}'),
            Text('Stock: ${product.quantity}'),
            Text(
              'Precio (${_getPriceTypeLabel(_selectedPriceType)}): \$${price.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: product.quantity > 0
            ? IconButton(
                icon: const Icon(Icons.add_shopping_cart),
                onPressed: () => _showAddProductDialog(product),
              )
            : const Text(
                'Sin stock',
                style: TextStyle(color: Colors.red),
              ),
      ),
    );
  }
  
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'electrónicos':
      case 'electronicos':
        return Icons.devices;
      case 'ropa':
        return Icons.checkroom;
      case 'comida':
        return Icons.restaurant;
      case 'hogar':
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
        return Icons.face;
      case 'automóvil':
      case 'automovil':
        return Icons.directions_car;
      default:
        return Icons.inventory_2;
    }
  }
  
  Widget _buildInvoiceItem(int index, InvoiceItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.productName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cantidad: ${item.quantity}'),
            Text('Precio unitario (${_getPriceTypeLabel(item.priceType)}): \$${item.unitPrice.toStringAsFixed(2)}'),
            Text(
              'Total: \$${item.total.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _removeItemFromInvoice(index),
        ),
      ),
    );
  }
  
  Widget _buildTotals() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Subtotal:', style: TextStyle(fontSize: 16)),
            Text('\$${_subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('IVA (${(_taxRate * 100).toStringAsFixed(0)}%):', style: const TextStyle(fontSize: 16)),
            Text('\$${_tax.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '\$${_total.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }
  
  void _showAddProductDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar ${product.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Stock disponible: ${product.quantity}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityController.text) ?? 0;
              if (quantity > 0 && quantity <= product.quantity) {
                _addProductToInvoice(product, quantity);
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Cantidad inválida'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}