import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inven_fact/services/client_service.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InvoiceScreen extends StatefulWidget {
  final List<Product> products;

  const InvoiceScreen({super.key, required this.products});

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  late Map<String, TextEditingController> _quantityControllers;
  late Map<String, String> _priceTypes;
  double _currentTotalAmount = 0.0;
  final InventoryService _inventoryService = InventoryService();
  final ClientService _clientService = ClientService();
  bool _isPrinting = false;
  String _clientName = '';

  @override
  void initState() {
    super.initState();
    _quantityControllers = {
      for (var p in widget.products) p.id: TextEditingController(text: '1')
    };
    _priceTypes = {for (var p in widget.products) p.id: 'retail'};
    _calculateTotal();
  }

  @override
  void dispose() {
    for (var controller in _quantityControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _calculateTotal() {
    double total = 0;
    for (var product in widget.products) {
      final quantity =
          int.tryParse(_quantityControllers[product.id]!.text) ?? 1;
      final priceType = _priceTypes[product.id] ?? 'retail';
      final price = priceType == 'wholesale' ? product.wholesalePrice : product.retailPrice;
      total += price * quantity;
    }
    setState(() {
      _currentTotalAmount = total;
    });
  }

  Future<void> _showClientDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seleccionar Cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Nombre del Cliente',
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _clientName = value;
                  });
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Continuar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _printInvoice() async {
    try {
      setState(() {
        _isPrinting = true;
      });

      String? result = await SunmiPrinter.initPrinter();
      bool isConnected = result != null;

      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo conectar a la impresora Sunmi.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final String companyName = prefs.getString('companyName') ?? 'Mi Empresa';
      final String companyAddress =
          prefs.getString('companyAddress') ?? 'Calle Falsa 123';
      final String companyPhone =
          prefs.getString('companyPhone') ?? '809-123-4567';
      final String companyRNC = prefs.getString('companyRNC') ?? '123456789';
      final String branch = prefs.getString('branch') ?? 'Sucursal Principal';

      // Header
      await SunmiPrinter.printText(
        companyName,
        style: SunmiTextStyle(
          fontSize: 26,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        companyAddress,
        style: SunmiTextStyle(
          fontSize: 22,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Sucursal: $branch',
        style: SunmiTextStyle(
          fontSize: 22,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'RNC: $companyRNC',
        style: SunmiTextStyle(
          fontSize: 22,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Tel: $companyPhone',
        style: SunmiTextStyle(
          fontSize: 22,
          bold: true,
          align: SunmiPrintAlign.CENTER,
        ),
      );
      await SunmiPrinter.lineWrap(2);

      // Client
      if (_clientName.isNotEmpty) {
        await SunmiPrinter.printText(
          'Cliente: $_clientName',
          style: SunmiTextStyle(
            fontSize: 22,
            bold: true,
            align: SunmiPrintAlign.LEFT,
          ),
        );
        await SunmiPrinter.lineWrap(1);
      }

      // Invoice details
      await SunmiPrinter.printText(
        '--------------------------------',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Producto        Cant.   Precio   Total',
        style: SunmiTextStyle(
          fontSize: 20,
          bold: true,
          align: SunmiPrintAlign.LEFT,
        ),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        '--------------------------------',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);

      // Products
      double total = 0;
      for (var product in widget.products) {
        final quantity = int.tryParse(_quantityControllers[product.id]!.text) ?? 1;
        final priceType = _priceTypes[product.id] ?? 'retail';
        final price = priceType == 'wholesale' ? product.wholesalePrice : product.retailPrice;
        final subtotal = price * quantity;
        total += subtotal;

        await SunmiPrinter.printText(
          '${product.name} x$quantity',
          style: SunmiTextStyle(
            fontSize: 18,
            align: SunmiPrintAlign.LEFT,
          ),
        );
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText(
          '  \$${subtotal.toStringAsFixed(2)}',
          style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
        );
        await SunmiPrinter.lineWrap(1);
      }

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        '================================',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'TOTAL: \$${total.toStringAsFixed(2)}',
        style: SunmiTextStyle(
          fontSize: 22,
          bold: true,
          align: SunmiPrintAlign.RIGHT,
        ),
      );
      await SunmiPrinter.lineWrap(3);

      // QR Code - Comentado porque no está disponible en esta versión
      // await SunmiPrinter.printQr(
      //   'Factura: ${DateTime.now().millisecondsSinceEpoch}',
      //   align: SunmiPrintAlign.CENTER,
      //   width: 200,
      //   height: 200,
      // );
      // await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText(
        'Gracias por su compra!',
        style: SunmiTextStyle(align: SunmiPrintAlign.CENTER),
      );
      await SunmiPrinter.lineWrap(3);

      await SunmiPrinter.cutPaper();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Factura impresa exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al imprimir: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Facturación'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _isPrinting ? null : _printInvoice,
            tooltip: 'Probar Impresora',
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Opciones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_add),
              title: const Text('Seleccionar Cliente'),
              onTap: () {
                Navigator.pop(context);
                _showClientDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.print),
              title: const Text('Probar Impresora'),
              onTap: () {
                Navigator.pop(context);
                _printInvoice();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Total: \$${_currentTotalAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: widget.products.length,
              itemBuilder: (context, index) {
                final product = widget.products[index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _quantityControllers[product.id],
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(3),
                                ],
                                decoration: const InputDecoration(
                                  labelText: 'Cantidad',
                                  border: OutlineInputBorder(),
                                ),
                                onChanged: (value) {
                                  final newQuantity = int.tryParse(value) ?? 1;
                                  if (newQuantity > product.quantity) {
                                    _quantityControllers[product.id]!.text =
                                        product.quantity.toString();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            'No puedes facturar más de ${product.quantity} unidades de ${product.name}'),
                                      ),
                                    );
                                  }
                                  _calculateTotal();
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _priceTypes[product.id],
                                decoration: const InputDecoration(
                                  labelText: 'Tipo de Precio',
                                  border: OutlineInputBorder(),
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'retail',
                                    child: Text('Al Detal'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'wholesale',
                                    child: Text('Al Mayor'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() {
                                    _priceTypes[product.id] = value!;
                                    _calculateTotal();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Precio: \$${(product.retailPrice.toStringAsFixed(2))}',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPrinting ? null : _printInvoice,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                    child: _isPrinting
                        ? const CircularProgressIndicator()
                        : const Text('Imprimir Factura'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isPrinting ? null : _showClientDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Seleccionar Cliente'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}