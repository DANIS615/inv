import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../models/product.dart';
import '../models/payment.dart';
import '../services/inventory_service.dart';
import '../services/client_service.dart';
import '../services/payment_service.dart';
import '../utils/event_bus.dart';
import 'credit_payment_screen.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Clase para manejar items de factura con cantidad
class InvoiceItem {
  final Product product;
  int quantity;
  String priceType;
  
  InvoiceItem({
    required this.product,
    this.quantity = 1,
    this.priceType = 'retail',
  });
  
  double get price {
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
  
  double get subtotal => quantity * price;
}

class ClientInvoiceScreen extends StatefulWidget {
  final String clientCode;

  const ClientInvoiceScreen({
    super.key,
    required this.clientCode,
  });

  @override
  State<ClientInvoiceScreen> createState() => _ClientInvoiceScreenState();
}

class _ClientInvoiceScreenState extends State<ClientInvoiceScreen> {
  final InventoryService _inventoryService = InventoryService();
  final ClientService _clientService = ClientService();
  
  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  List<InvoiceItem> _selectedProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  
  Client? _client;
  double _subtotal = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  // Información del último pago para impresión en Sunmi
  double? _lastPaymentAmount; // monto pagado en esta operación
  double? _lastRemainingBalance; // saldo restante después del pago

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProducts);
    _loadData();
  }

  void _showSelectedProductsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.35,
        minChildSize: 0.2,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart),
                  const SizedBox(width: 8),
                  Text('Productos seleccionados (${_selectedProducts.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: _selectedProducts.length,
                  itemBuilder: (context, index) => _buildInvoiceItemCard(_selectedProducts[index]),
                ),
              ),
              const Divider(),
              _buildSafeRow(label: 'Subtotal:', value: 'RD\$${_subtotal.toStringAsFixed(2)}'),
              _buildSafeRow(label: 'IVA (18%):', value: 'RD\$${_tax.toStringAsFixed(2)}'),
              _buildSafeRow(
                label: 'Total:',
                value: 'RD\$${_total.toStringAsFixed(2)}',
                labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar información del cliente
      final client = await _clientService.getClientByCode(widget.clientCode);
      if (client != null) {
        setState(() {
          _client = client;
        });
      }

      // Cargar productos del inventario
      final products = await _inventoryService.getProducts();
      setState(() {
        _products = products;
        _filteredProducts = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
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
        return product.name.toLowerCase().contains(query) ||
               product.description.toLowerCase().contains(query) ||
               product.category.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _toggleProduct(Product product) {
    setState(() {
      final existingIndex = _selectedProducts.indexWhere((item) => item.product.id == product.id);
      if (existingIndex != -1) {
        _selectedProducts.removeAt(existingIndex);
      } else {
        // Agregar producto con cantidad inicial de 1
        _selectedProducts.add(InvoiceItem(product: product, quantity: 1));
        print('🔍 DEBUG: Producto agregado: ${product.name}, cantidad: 1');
      }
      _calculateTotal();
    });
  }

  void _updateQuantity(InvoiceItem item, int newQuantity) {
    print('🔍 DEBUG: Actualizando cantidad de ${item.product.name}: ${item.quantity} → $newQuantity');
    
    if (newQuantity <= 0) {
      _removeProduct(item);
      return;
    }
    
    if (newQuantity > item.product.quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No puedes facturar más de ${item.product.quantity} unidades de ${item.product.name}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() {
      item.quantity = newQuantity;
      print('🔍 DEBUG: Cantidad actualizada: ${item.quantity}');
      _calculateTotal();
    });
  }

  void _updatePriceType(InvoiceItem item, String newPriceType) {
    setState(() {
      item.priceType = newPriceType;
      _calculateTotal();
    });
  }

  void _removeProduct(InvoiceItem item) {
    setState(() {
      _selectedProducts.remove(item);
      _calculateTotal();
    });
  }

  void _calculateTotal() {
    _subtotal = _selectedProducts.fold(0.0, (sum, item) => sum + item.subtotal);
    _tax = _subtotal * 0.18; // 18% IVA
    _total = _subtotal + _tax;
  }

  // Helper para crear rows que no se desborden
  Widget _buildSafeRow({
    required String label,
    required String value,
    TextStyle? labelStyle,
    TextStyle? valueStyle,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: labelStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: valueStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceConfirmationDialog() {
    // Variables de estado para el diálogo - FUERA del builder
    PaymentType selectedPaymentType = PaymentType.full;
    final TextEditingController amountController = TextEditingController();
    bool showAmountField = false;
    PaymentMethod selectedPaymentMethod = PaymentMethod.cash;
    final TextEditingController referenceController = TextEditingController();
    
    return StatefulBuilder(
      builder: (context, setState) {

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.receipt_long,
                color: _client?.accountType == AccountType.credito 
                    ? Colors.orange 
                    : Colors.blue,
              ),
              const SizedBox(width: 8),
              Text('Confirmar Factura'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Información de la factura
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          Text(
                            'Detalles de la Factura',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildSafeRow(
                        label: 'Cliente:', 
                        value: _client?.name ?? 'N/A',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSafeRow(
                        label: 'Código:', 
                        value: widget.clientCode,
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSafeRow(
                        label: 'Productos:', 
                        value: '${_selectedProducts.length}',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSafeRow(
                        label: 'Subtotal:', 
                        value: 'RD\$${_subtotal.toStringAsFixed(2)}',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildSafeRow(
                        label: 'IVA (18%):', 
                        value: 'RD\$${_tax.toStringAsFixed(2)}',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[700],
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const Divider(color: Colors.grey, height: 24),
                      _buildSafeRow(
                        label: 'Total:',
                        value: 'RD\$${_total.toStringAsFixed(2)}',
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 16,
                        ),
                        valueStyle: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Información del cliente
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _client?.accountType == AccountType.credito 
                        ? Colors.orange[50] 
                        : Colors.green[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _client?.accountType == AccountType.credito 
                          ? Colors.orange[300]! 
                          : Colors.green[300]!,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _client?.accountType == AccountType.credito 
                            ? Icons.credit_card 
                            : Icons.money,
                        color: _client?.accountType == AccountType.credito 
                            ? Colors.orange[700] 
                            : Colors.green[700],
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _client?.accountType == AccountType.credito 
                                  ? 'Cliente de Crédito' 
                                  : 'Cliente de Contado',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _client?.accountType == AccountType.credito 
                                    ? Colors.orange[700] 
                                    : Colors.green[700],
                              ),
                            ),
                            if (_client?.accountType == AccountType.credito) ...[
                              Text(
                                'Saldo pendiente: RD\$${_client?.pendingBalance.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: Colors.orange[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Opciones de pago para clientes de crédito
                if (_client?.accountType == AccountType.credito) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Tipo de Pago:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Pago completo
                  RadioListTile<PaymentType>(
                    title: const Text('Pago Completo'),
                    subtitle: Text('RD\$${_total.toStringAsFixed(2)}'),
                    value: PaymentType.full,
                    groupValue: selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentType = value!;
                        showAmountField = false;
                        amountController.text = _total.toStringAsFixed(2);
                      });
                    },
                    activeColor: Colors.green,
                  ),
                  
                  // Pago parcial
                  RadioListTile<PaymentType>(
                    title: const Text('Pago Parcial'),
                    subtitle: const Text('Especificar monto a pagar'),
                    value: PaymentType.partial,
                    groupValue: selectedPaymentType,
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentType = value!;
                        showAmountField = true;
                        amountController.text = '';
                      });
                    },
                    activeColor: Colors.orange,
                  ),

                  // Campo de monto para pago parcial
                  if (showAmountField) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Monto a pagar',
                        hintText: 'Ej: 100.00',
                        prefixText: 'RD\$ ',
                        border: const OutlineInputBorder(),
                        suffixText: 'de RD\$${_total.toStringAsFixed(2)}',
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                      ],
                    ),
                  ],
                ],

                // Método de pago para clientes de crédito
                if (_client?.accountType == AccountType.credito) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Método de Pago:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  DropdownButtonFormField<PaymentMethod>(
                    value: selectedPaymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar método',
                      border: OutlineInputBorder(),
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: PaymentMethod.cash,
                        child: Text('Efectivo', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.transfer,
                        child: Text('Transferencia Bancaria', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.check,
                        child: Text('Cheque', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.creditCard,
                        child: Text('Tarjeta de Crédito', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.debitCard,
                        child: Text('Tarjeta de Débito', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.mobilePayment,
                        child: Text('Pago Móvil', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: PaymentMethod.other,
                        child: Text('Otro', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedPaymentMethod = value!;
                      });
                    },
                  ),

                  // Campo de referencia para métodos que la requieren
                  if (selectedPaymentMethod == PaymentMethod.transfer || 
                      selectedPaymentMethod == PaymentMethod.check ||
                      selectedPaymentMethod == PaymentMethod.creditCard ||
                      selectedPaymentMethod == PaymentMethod.debitCard ||
                      selectedPaymentMethod == PaymentMethod.mobilePayment) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: referenceController,
                      decoration: InputDecoration(
                        labelText: 'Referencia/Número',
                        hintText: 'Ej: 123456789',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ],

                const SizedBox(height: 16),
                Text(
                  '¿Deseas procesar esta factura?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                double? paymentAmount;
                if (selectedPaymentType == PaymentType.partial && showAmountField) {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0 || amount > _total) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Monto inválido. Debe estar entre 0 y ${_total.toStringAsFixed(2)}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  paymentAmount = amount;
                }
                
                // Validar referencia si es requerida
                if (_client?.accountType == AccountType.credito && 
                    (selectedPaymentMethod == PaymentMethod.transfer || 
                     selectedPaymentMethod == PaymentMethod.check ||
                     selectedPaymentMethod == PaymentMethod.creditCard ||
                     selectedPaymentMethod == PaymentMethod.debitCard ||
                     selectedPaymentMethod == PaymentMethod.mobilePayment) &&
                    referenceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa la referencia/número del pago'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.of(context).pop({
                  'paymentType': selectedPaymentType,
                  'paymentAmount': paymentAmount,
                  'paymentMethod': selectedPaymentMethod,
                  'reference': referenceController.text.trim().isNotEmpty ? referenceController.text.trim() : null,
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _client?.accountType == AccountType.credito 
                    ? Colors.orange 
                    : Colors.blue,
              ),
              child: Text(
                _client?.accountType == AccountType.credito 
                    ? 'Procesar Pago' 
                    : 'Procesar Factura',
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildClientInfo() {
    if (_client == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.person,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cliente: ${_client!.name}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Código: ${_client!.code}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  _client!.accountType == AccountType.credito 
                      ? Icons.account_balance_wallet 
                      : Icons.payment,
                  size: 16,
                  color: _client!.accountType == AccountType.credito 
                      ? Colors.blue[700] 
                      : Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  'Tipo: ${_client!.accountType == AccountType.credito ? 'Crédito' : 'Contado'}',
                  style: TextStyle(
                    color: _client!.accountType == AccountType.credito 
                        ? Colors.blue[700] 
                        : Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (_client!.accountType == AccountType.credito && _client!.pendingBalance > 0) ...[
              const SizedBox(height: 4),
              Text(
                'Saldo pendiente: RD\$${_client!.pendingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final selectedItemIndex = _selectedProducts.indexWhere((item) => item.product.id == product.id);
    final selectedItem = selectedItemIndex != -1 ? _selectedProducts[selectedItemIndex] : null;
    final isSelected = selectedItem != null && selectedItem.quantity > 0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: isSelected ? Colors.blue[50] : null,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
          child: Icon(
            isSelected ? Icons.check : Icons.add,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
        title: Text(
          product.name,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.blue[700] : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Flexible(
                  flex: 2,
                  child: Text(
                    'RD\$${product.retailPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      product.category,
                      style: const TextStyle(fontSize: 11),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  flex: 1,
                  child: Text(
                    'Stock: ${product.quantity}',
                    style: TextStyle(
                      fontSize: 11,
                      color: product.quantity > 0 ? Colors.green[700] : Colors.red[700],
                    ),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Controles de cantidad directamente en la lista
            if (isSelected) Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  tooltip: 'Reducir',
                  onPressed: selectedItem != null ? () {
                    if (selectedItem.quantity > 0) {
                      _updateQuantity(selectedItem, selectedItem.quantity - 1);
                    }
                  } : null,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    '${selectedItem?.quantity ?? 0}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Aumentar',
                  onPressed: selectedItem != null ? () {
                    _updateQuantity(selectedItem, selectedItem.quantity + 1);
                  } : null,
                ),
              ],
            )
            else Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                icon: const Icon(Icons.add_circle),
                color: Theme.of(context).primaryColor,
                tooltip: 'Agregar',
                onPressed: () {
                  // Si no está seleccionado, agregar con cantidad 1
                  _toggleProduct(product);
                },
              ),
            ),
            if (isSelected) ...[
              const SizedBox(height: 8),
              _buildSafeRow(
                label: 'Cantidad: ${selectedItem?.quantity ?? 0}',
                value: 'Subtotal: RD\$${selectedItem?.subtotal.toStringAsFixed(2) ?? '0.00'}',
                labelStyle: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
                valueStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _toggleProduct(product),
        enabled: product.quantity > 0,
      ),
    );
  }

  Widget _buildSelectedProducts() {
    if (_selectedProducts.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Productos Seleccionados (${_selectedProducts.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Lista desplazable de ítems seleccionados (no ocupa todo el alto)
            Flexible(
              fit: FlexFit.loose,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _selectedProducts.length,
                itemBuilder: (context, index) => _buildInvoiceItemCard(_selectedProducts[index]),
              ),
            ),

            const Divider(),
            _buildSafeRow(
              label: 'Subtotal:',
              value: 'RD\$${_subtotal.toStringAsFixed(2)}',
            ),
            _buildSafeRow(
              label: 'IVA (18%):',
              value: 'RD\$${_tax.toStringAsFixed(2)}',
            ),
            const Divider(),
            _buildSafeRow(
              label: 'Total:',
              value: 'RD\$${_total.toStringAsFixed(2)}',
              labelStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              valueStyle: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedProducts.isNotEmpty ? _processInvoice : null,
                icon: const Icon(Icons.receipt_long),
                label: const Text('Generar Factura'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItemCard(InvoiceItem item) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _removeProduct(item),
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Eliminar producto',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // Cantidad con controles +/-
                Flexible(
                  flex: 2,
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        tooltip: 'Reducir cantidad',
                        onPressed: () => _updateQuantity(item, item.quantity - 1),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white,
                          ),
                          child: Text(
                            '${item.quantity}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        tooltip: 'Aumentar cantidad',
                        onPressed: () => _updateQuantity(item, item.quantity + 1),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Tipo de precio
                Flexible(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    value: item.priceType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Precio',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'retail',
                        child: Text('Detalle', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'wholesale',
                        child: Text('Por Mayor', overflow: TextOverflow.ellipsis),
                      ),
                      DropdownMenuItem(
                        value: 'distribution',
                        child: Text('Distribución', overflow: TextOverflow.ellipsis),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _updatePriceType(item, value);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildSafeRow(
              label: 'Precio unitario: RD\$${item.price.toStringAsFixed(2)}',
              value: 'Subtotal: RD\$${item.subtotal.toStringAsFixed(2)}',
              labelStyle: const TextStyle(fontSize: 14),
              valueStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _removeProduct(item),
                icon: const Icon(Icons.delete, color: Colors.red),
                label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processInvoice() async {
    print('🔍 DEBUG: Iniciando proceso de factura');
    
    // Mostrar diálogo de confirmación con opciones de pago
    final paymentInfo = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _buildInvoiceConfirmationDialog(),
    );

    if (paymentInfo == null) {
      print('🔍 DEBUG: Usuario canceló el diálogo');
      return;
    }

    print('🔍 DEBUG: Información de pago recibida: $paymentInfo');

    // Verificar tipo de cuenta del cliente
    if (_client?.accountType == AccountType.contado) {
      print('🔍 DEBUG: Cliente de contado - procesando pago inmediato');
      // Cliente de contado - procesar pago inmediato
      await _processCashPayment();
    } else {
      print('🔍 DEBUG: Cliente de crédito - procesando según opción');
      // Cliente de crédito - procesar según la opción seleccionada
      final paymentType = paymentInfo['paymentType'] as PaymentType;
      final paymentAmount = paymentInfo['paymentAmount'] as double?;
      final paymentMethod = paymentInfo['paymentMethod'] as PaymentMethod;
      final reference = paymentInfo['reference'] as String?;
      
      print('🔍 DEBUG: Tipo de pago: $paymentType, Monto: $paymentAmount, Método: $paymentMethod, Referencia: $reference');
      
      // Procesar pago directamente con toda la información
      await _processCreditPayment(paymentType, paymentAmount, paymentMethod, reference);
    }
  }

  Future<void> _processCashPayment() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text('Procesando pago de contado...'),
            ),
          ],
        ),
      ),
    );

    try {
      // Procesar pago usando el servicio de pagos (para guardar historial)
      final paymentService = PaymentService();
      final result = await paymentService.processPayment(
        clientId: _client!.id.toString(),
        clientCode: _client!.code,
        clientName: _client!.name,
        totalAmount: _total,
        paymentAmount: _total, // Pago completo para contado
        paymentType: PaymentType.full,
        paymentMethod: PaymentMethod.cash,
        description: 'Pago de contado - Factura completa',
        invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
        increaseDebtByInvoiceTotal: false, // No incrementar deuda para contado
      );

      if (!result.success) {
        // Cerrar diálogo de carga
        if (mounted) Navigator.of(context).pop();
        
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al procesar pago: ${result.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Actualizar inventario
      for (final item in _selectedProducts) {
        final updatedProduct = item.product.copyWith(
          quantity: item.product.quantity - item.quantity,
        );
        await _inventoryService.updateProduct(updatedProduct);
      }

      // Actualizar fecha de última compra del cliente
      final updatedClient = _client!.copyWith(lastPurchase: DateTime.now());
      await _clientService.updateClient(updatedClient);

      // Cerrar diálogo de carga
      if (mounted) Navigator.of(context).pop();

      // Imprimir factura
      await _printInvoice();

      // Notificar dashboard para refrescar métricas
      try { 
        EventBus().fire('paymentsChanged');
        EventBus().fire('saleCompleted');
      } catch (_) {}

      // Mostrar éxito
      if (mounted) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Expanded(
              child: Text('Pago de Contado Procesado'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cliente: ${_client?.name ?? 'N/A'}'),
            Text('Código: ${widget.clientCode}'),
            Text('Productos: ${_selectedProducts.length}'),
            Text('Total: RD\$${_total.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text(
                  '¡Pago de contado procesado exitosamente!',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
                const Text(
                  'El inventario ha sido actualizado y la factura ha sido impresa.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Cerrar diálogo
              Navigator.of(context).pop(); // Volver al inicio
            },
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );
      }
    } catch (e) {
      // Cerrar diálogo de carga
      if (mounted) Navigator.of(context).pop();

      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar el pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _testPrinter() async {
    try {
      print('🖨️ DEBUG: Probando conexión con impresora...');
      
      // Inicializar la impresora
      await SunmiPrinter.initPrinter();
      print('🖨️ DEBUG: Impresora inicializada');

      // Imprimir texto de prueba
      await SunmiPrinter.printText('PRUEBA DE IMPRESORA SUNMI');
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.printText('Conexión exitosa!');
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Prueba de impresión exitosa!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('🖨️ DEBUG: Error en prueba: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error en prueba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printInvoice() async {
    try {
      print('🖨️ DEBUG: Iniciando impresión...');
      
      // Inicializar la impresora
      await SunmiPrinter.initPrinter();
      print('🖨️ DEBUG: Impresora inicializada, iniciando impresión...');

      final prefs = await SharedPreferences.getInstance();
      final String companyName = prefs.getString('companyName') ?? 'Mi Empresa';
      final String companyAddress = prefs.getString('companyAddress') ?? 'Calle Falsa 123';
      final String companyPhone = prefs.getString('companyPhone') ?? '809-123-4567';
      final String companyRNC = prefs.getString('companyRNC') ?? '123456789';
      final String branch = prefs.getString('branch') ?? 'Sucursal Principal';
      final String sellerName = prefs.getString('seller_name') ?? 'Vendedor';
      final String sellerId = prefs.getString('seller_id') ?? 'N/A';

      final String invoiceId = DateTime.now().millisecondsSinceEpoch.toString();
      final DateTime now = DateTime.now();
      String dateStr = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      String timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

      // Header
      await SunmiPrinter.printText(companyName);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(companyAddress);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Sucursal: $branch');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('RNC: $companyRNC');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Tel: $companyPhone');
      await SunmiPrinter.lineWrap(2);

      // Factura / Vendedor / Fecha
      await SunmiPrinter.printText('Factura: $invoiceId');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Fecha: $dateStr   Hora: $timeStr');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Vendedor: $sellerName  (ID: $sellerId)');
      await SunmiPrinter.lineWrap(2);

      // Client info
      if (_client != null) {
        await SunmiPrinter.printText('Cliente: ${_client!.name}');
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText('Código: ${_client!.code}');
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText('Tipo: ${_client!.accountType == AccountType.credito ? 'Crédito' : 'Contado'}');
        if (_client!.rnc != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('RNC: ${_client!.rnc}');
        }
        if (_client!.cedula != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('Cédula: ${_client!.cedula}');
        }
        if (_client!.direccion != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('Dirección: ${_client!.direccion}');
        }
        if (_client!.telefono != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('Teléfono: ${_client!.telefono}');
        }
        await SunmiPrinter.lineWrap(2);
      }

      // Invoice details
      await SunmiPrinter.printText('--------------------------------');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Producto            Cant  Precio   Importe');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('--------------------------------');
      await SunmiPrinter.lineWrap(1);

      // Products (alineados)
      int totalUnits = 0;
      for (var item in _selectedProducts) {
        totalUnits += item.quantity;
        // Col 1: nombre 16, Col 2: cant 4, Col 3: precio 8, Col 4: total 8
        String name = item.product.name;
        if (name.length > 16) name = name.substring(0, 13) + '...';
        name = name.padRight(16);
        String qty = item.quantity.toString().padLeft(4);
        String priceStr = item.price.toStringAsFixed(2).padLeft(8);
        String totalStr = item.subtotal.toStringAsFixed(2).padLeft(8);
        await SunmiPrinter.printText('$name $qty $priceStr $totalStr');
        await SunmiPrinter.lineWrap(1);
      }
      await SunmiPrinter.lineWrap(1);

      // Totals
      await SunmiPrinter.printText('--------------------------------');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Ítems: $totalUnits');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Subtotal: RD\$${_subtotal.toStringAsFixed(2)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('ITBIS (18%): RD\$${_tax.toStringAsFixed(2)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('TOTAL: RD\$${_total.toStringAsFixed(2)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Condición: ${_client?.accountType == AccountType.credito ? 'Crédito' : 'Contado'}');
      // Si fue un pago de crédito, imprimir resumen de pago
      if (_client?.accountType == AccountType.credito) {
        if (_lastPaymentAmount != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('Pago realizado: RD\$${_lastPaymentAmount!.toStringAsFixed(2)}');
        }
        if (_lastRemainingBalance != null) {
          await SunmiPrinter.lineWrap(1);
          await SunmiPrinter.printText('Saldo restante: RD\$${_lastRemainingBalance!.toStringAsFixed(2)}');
        }
      }
      await SunmiPrinter.lineWrap(3);

      // Footer
      await SunmiPrinter.printText('Gracias por su compra!');
      await SunmiPrinter.lineWrap(3);

      await SunmiPrinter.cutPaper();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Factura impresa exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir la factura: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _processCreditPayment(PaymentType paymentType, double? paymentAmount, PaymentMethod paymentMethod, String? reference) async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(
              child: Text('Procesando pago...'),
            ),
          ],
        ),
      ),
    );

    try {
      // Determinar el monto a pagar
      final amountToPay = paymentAmount ?? _total;
      
      // Procesar pago usando el servicio de pagos
      final paymentService = PaymentService();
      final result = await paymentService.processPayment(
        clientId: _client!.id.toString(),
        clientCode: _client!.code,
        clientName: _client!.name,
        totalAmount: _total,
        paymentAmount: amountToPay,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        description: 'Pago de factura - ${paymentType == PaymentType.full ? 'Completo' : 'Parcial'}',
        invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
        reference: reference,
        increaseDebtByInvoiceTotal: true,
      );

      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        // Actualizar inventario
        await _updateInventory();

        // Refrescar datos del cliente para mostrar saldo actualizado
        final refreshed = await _clientService.getClientByCode(widget.clientCode);
        if (refreshed != null) {
          setState(() {
            _client = refreshed;
          });
        }

        // Imprimir factura
        _lastPaymentAmount = amountToPay;
        _lastRemainingBalance = result.remainingBalance;
        await _printInvoice();

        // Notificar dashboard para refrescar métricas de pagos/inventario
        try { EventBus().fire('paymentsChanged'); } catch (_) {}

        // Mostrar resultado exitoso
        if (mounted) {
          await _showPaymentResult(result);
        }
      } else {
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _navigateToPaymentScreen() async {
    print('🔍 DEBUG: Navegando a pantalla de pagos');
    print('🔍 DEBUG: Código cliente: ${widget.clientCode}');
    print('🔍 DEBUG: Total factura: $_total');
    
    // Navegar a la pantalla de gestión de pagos
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreditPaymentScreen(
          clientCode: widget.clientCode,
          invoiceTotal: _total,
          invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
        ),
      ),
    );
    
    print('🔍 DEBUG: Resultado de navegación: $result');

    // Si el pago fue exitoso, actualizar inventario
    if (result == true) {
      try {
        // Actualizar inventario
        for (final item in _selectedProducts) {
          final updatedProduct = item.product.copyWith(
            quantity: item.product.quantity - item.quantity,
          );
          await _inventoryService.updateProduct(updatedProduct);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Factura procesada exitosamente'),
              backgroundColor: Colors.green,
            ),
          );

          // Volver al inicio
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al actualizar inventario: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _testPrinter,
            tooltip: 'Probar Impresora',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Volver al Inicio',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildClientInfo()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Buscar productos...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                _filteredProducts.isEmpty
                    ? const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: Text('No hay productos disponibles')),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductCard(_filteredProducts[index]),
                          childCount: _filteredProducts.length,
                        ),
                      ),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, -2)),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total: RD\$${_total.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                    Text('Subtotal RD\$${_subtotal.toStringAsFixed(2)}  •  IVA RD\$${_tax.toStringAsFixed(2)}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TextButton.icon(
                  onPressed: _selectedProducts.isEmpty ? null : _showSelectedProductsSheet,
                  icon: const Icon(Icons.list_alt),
                  label: Text('Seleccionados (${_selectedProducts.length})'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _selectedProducts.isNotEmpty ? _processInvoice : null,
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('Facturar'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processFullCreditPayment() async {
    // Mostrar indicador de carga
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Procesar pago completo usando el servicio de pagos
      final paymentService = PaymentService();
      final result = await paymentService.processPayment(
        clientId: _client!.id.toString(),
        clientCode: _client!.code,
        clientName: _client!.name,
        totalAmount: _total,
        paymentAmount: _total,
        paymentType: PaymentType.full,
        paymentMethod: PaymentMethod.cash,
        description: 'Pago completo de factura',
        invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();

      if (result.success) {
        // Actualizar inventario
        await _updateInventory();

        // Mostrar resultado exitoso
        if (mounted) {
          await _showPaymentResult(result);
        }
      } else {
        // Mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      // Cerrar indicador de carga
      if (mounted) Navigator.of(context).pop();
      
      // Mostrar error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  Future<void> _updateInventory() async {
    try {
      final inventoryService = InventoryService();
      
      for (final item in _selectedProducts) {
        final product = item.product;
        final newQuantity = product.quantity - item.quantity;
        
        if (newQuantity >= 0) {
          final updatedProduct = product.copyWith(quantity: newQuantity);
          await inventoryService.updateProduct(updatedProduct);
        }
      }
    } catch (e) {
      print('Error al actualizar inventario: $e');
    }
  }

  Future<void> _showPaymentResult(PaymentResult result) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(result.success ? 'Pago Exitoso' : 'Error en el Pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.payment != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text('Detalles del Pago:'),
              const SizedBox(height: 8),
              _buildSafeRow(label: 'Cliente:', value: result.payment!.clientName),
              _buildSafeRow(label: 'Monto Pagado:', value: 'RD\$${result.payment!.amount.toStringAsFixed(2)}'),
              _buildSafeRow(label: 'Monto Total:', value: 'RD\$${result.payment!.totalAmount.toStringAsFixed(2)}'),
              _buildSafeRow(label: 'Tipo de Pago:', value: _getPaymentTypeLabel(result.payment!.paymentType)),
              _buildSafeRow(label: 'Método de Pago:', value: _getPaymentMethodLabel(result.payment!.paymentMethod)),
              if (result.payment!.reference != null)
                _buildSafeRow(label: 'Referencia:', value: result.payment!.reference!),
              _buildSafeRow(label: 'Fecha:', value: _formatDateTime(result.payment!.createdAt)),
              if (result.remainingBalance != null && result.remainingBalance! > 0)
                _buildSafeRow(label: 'Saldo Pendiente:', value: 'RD\$${result.remainingBalance!.toStringAsFixed(2)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (result.success) {
                // Limpiar productos seleccionados y volver al inicio
                setState(() {
                  _selectedProducts.clear();
                  _calculateTotals();
                });
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            child: Text(result.success ? 'Finalizar' : 'Cerrar'),
          ),
        ],
      ),
    );
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'Efectivo';
      case PaymentType.partial:
        return 'Pago Parcial';
      case PaymentType.full:
        return 'Pago Completo';
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia Bancaria';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.mobilePayment:
        return 'Pago Móvil';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _calculateTotals() {
    _subtotal = _selectedProducts.fold(0.0, (sum, item) => sum + item.subtotal);
    _tax = _subtotal * 0.18; // 18% IVA
    _total = _subtotal + _tax;
  }
}
