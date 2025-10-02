import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../models/product.dart';
import '../services/inventory_service.dart';
import '../utils/event_bus.dart';

class AddProductScreen extends StatefulWidget {
  final Product? product;

  const AddProductScreen({super.key, this.product});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _inventoryService = InventoryService();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _wholesalePriceController;
  late TextEditingController _retailPriceController;
  late TextEditingController _distributionPriceController;
  late TextEditingController _quantityController;
  late TextEditingController _categoryController;
  late TextEditingController _barcodeController;
  TextEditingController _minStockController = TextEditingController();

  bool _isLoading = false;
  String _selectedCategory = 'General';
  File? _imageFile;
  bool _autoGenerateBarcode = true;
  bool _autoCalculatePrices = true;
  int _minStock = 5;

  // Lista de categorías predefinidas con sus iconos
  final List<Map<String, dynamic>> _categories = [
    {'name': 'General', 'icon': Icons.inventory_2},
    {'name': 'Electrónicos', 'icon': Icons.devices},
    {'name': 'Ropa', 'icon': Icons.checkroom},
    {'name': 'Comida', 'icon': Icons.restaurant},
    {'name': 'Hogar', 'icon': Icons.home},
    {'name': 'Deportes', 'icon': Icons.sports},
    {'name': 'Libros', 'icon': Icons.book},
    {'name': 'Juguetes', 'icon': Icons.toys},
    {'name': 'Herramientas', 'icon': Icons.build},
    {'name': 'Belleza', 'icon': Icons.face},
    {'name': 'Automóvil', 'icon': Icons.directions_car},
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.product?.description ?? '');
    _wholesalePriceController = TextEditingController(
      text: widget.product?.wholesalePrice.toString() ?? '',
    );
    _retailPriceController = TextEditingController(
      text: widget.product?.retailPrice.toString() ?? '',
    );
    _distributionPriceController = TextEditingController(
      text: widget.product?.distributionPrice.toString() ?? '',
    );
    _quantityController = TextEditingController(
      text: widget.product?.quantity.toString() ?? '',
    );
    _categoryController =
        TextEditingController(text: widget.product?.category ?? 'General');
    _barcodeController = TextEditingController(
      text: widget.product?.barcode ?? '',
    );
    _minStockController.text = '5';
    _selectedCategory = widget.product?.category ?? 'General';
    if (widget.product?.imageUrl != null) {
      _imageFile = File(widget.product!.imageUrl!);
    }
    
    // Generar código de barras si es un producto nuevo
    if (widget.product == null) {
      _barcodeController.text = _generateBarcode();
    }
    
    // Agregar listeners para cálculos automáticos
    _wholesalePriceController.addListener(_calculateRetailPrice);
    _retailPriceController.addListener(_calculateDistributionPrice);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _wholesalePriceController.dispose();
    _retailPriceController.dispose();
    _distributionPriceController.dispose();
    _quantityController.dispose();
    _categoryController.dispose();
    _barcodeController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  String _generateBarcode() {
    // Generar código de barras único basado en timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return timestamp.toString().substring(5); // Últimos dígitos del timestamp
  }

  void _calculateRetailPrice() {
    if (_autoCalculatePrices && _wholesalePriceController.text.isNotEmpty) {
      final wholesalePrice = double.tryParse(_wholesalePriceController.text);
      if (wholesalePrice != null) {
        // Margen del 50% para precio retail
        final retailPrice = wholesalePrice * 1.5;
        _retailPriceController.text = retailPrice.toStringAsFixed(2);
      }
    }
  }

  void _calculateDistributionPrice() {
    if (_autoCalculatePrices && _retailPriceController.text.isNotEmpty) {
      final retailPrice = double.tryParse(_retailPriceController.text);
      if (retailPrice != null) {
        // Margen del 30% para precio de distribución
        final distributionPrice = retailPrice * 1.3;
        _distributionPriceController.text = distributionPrice.toStringAsFixed(2);
      }
    }
  }

  void _generateNewBarcode() {
    setState(() {
      _barcodeController.text = _generateBarcode();
    });
  }

  Future<void> _validateAndGenerateBarcode() async {
    final currentBarcode = _barcodeController.text.trim();
    if (currentBarcode.isNotEmpty) {
      final barcodeExists = await _inventoryService.isBarcodeExists(currentBarcode);
      if (barcodeExists) {
        // Generar un nuevo código si el actual ya existe
        String newBarcode;
        do {
          newBarcode = _generateBarcode();
        } while (await _inventoryService.isBarcodeExists(newBarcode));
        
        setState(() {
          _barcodeController.text = newBarcode;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('El código "$currentBarcode" ya existe. Se generó un nuevo código: $newBarcode'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  void _showDescriptionTemplates() {
    final templates = _getDescriptionTemplates();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Plantillas Rápidas'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selecciona una plantilla para completar automáticamente la descripción y categoría:',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
              final template = templates[index];
              return ListTile(
                leading: Icon(template['icon']),
                title: Text(template['title']),
                subtitle: Text(template['description']),
                onTap: () {
                  Navigator.pop(context);
                  _applyTemplate(template);
                },
              );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _getDescriptionTemplates() {
    return [
      {
        'icon': Icons.devices,
        'title': 'Electrónicos',
        'description': 'Producto electrónico de alta calidad con garantía. Incluye manual de usuario y accesorios necesarios.',
        'suggestedPrice': 500.0,
      },
      {
        'icon': Icons.checkroom,
        'title': 'Ropa',
        'description': 'Prenda de vestir confeccionada con materiales de primera calidad. Disponible en diferentes tallas y colores.',
        'suggestedPrice': 150.0,
      },
      {
        'icon': Icons.restaurant,
        'title': 'Comida',
        'description': 'Producto alimenticio fresco y de calidad. Perfecto para consumo inmediato o almacenamiento.',
        'suggestedPrice': 50.0,
      },
      {
        'icon': Icons.home,
        'title': 'Hogar',
        'description': 'Artículo para el hogar funcional y decorativo. Fácil de instalar y mantener.',
        'suggestedPrice': 200.0,
      },
      {
        'icon': Icons.sports,
        'title': 'Deportes',
        'description': 'Equipo deportivo profesional para mejorar el rendimiento. Resistente y duradero.',
        'suggestedPrice': 300.0,
      },
      {
        'icon': Icons.book,
        'title': 'Libros',
        'description': 'Libro educativo o de entretenimiento. Encuadernación de calidad y páginas resistentes.',
        'suggestedPrice': 100.0,
      },
      {
        'icon': Icons.toys,
        'title': 'Juguetes',
        'description': 'Juguete seguro y educativo para niños. Cumple con estándares de seguridad internacionales.',
        'suggestedPrice': 80.0,
      },
      {
        'icon': Icons.build,
        'title': 'Herramientas',
        'description': 'Herramienta profesional de alta durabilidad. Ideal para trabajos especializados.',
        'suggestedPrice': 250.0,
      },
      {
        'icon': Icons.face,
        'title': 'Belleza',
        'description': 'Producto de belleza y cuidado personal. Formulado con ingredientes naturales.',
        'suggestedPrice': 120.0,
      },
      {
        'icon': Icons.directions_car,
        'title': 'Automóvil',
        'description': 'Accesorio o repuesto para vehículos. Compatible con múltiples marcas y modelos.',
        'suggestedPrice': 400.0,
      },
    ];
  }

  void _applyTemplate(Map<String, dynamic> template) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(template['icon'], color: Colors.blue),
              const SizedBox(width: 8),
              Text('Aplicar Plantilla: ${template['title']}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Esta plantilla completará automáticamente:'),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.description, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('Descripción'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.category, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text('Categoría: ${template['title']}'),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.attach_money, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text('Precio sugerido: RD\$${template['suggestedPrice']}'),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                '¿Quieres aplicar también el precio sugerido?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyTemplateData(template, includePrices: false);
              },
              child: const Text('Solo Descripción y Categoría'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _applyTemplateData(template, includePrices: true);
              },
              child: const Text('Incluir Precio Sugerido'),
            ),
          ],
        );
      },
    );
  }

  void _applyTemplateData(Map<String, dynamic> template, {required bool includePrices}) {
    setState(() {
      // Aplicar descripción y categoría
      _descriptionController.text = template['description'];
      _selectedCategory = template['title'];
      
      // Aplicar precios si se solicita
      if (includePrices) {
        final suggestedPrice = template['suggestedPrice'] as double;
        _wholesalePriceController.text = suggestedPrice.toStringAsFixed(2);
        
        // Si está habilitado el cálculo automático, calcular los otros precios
        if (_autoCalculatePrices) {
          _calculateRetailPrice();
          _calculateDistributionPrice();
        }
      }
    });
    
    // Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          includePrices 
            ? 'Plantilla aplicada: descripción, categoría y precios'
            : 'Plantilla aplicada: descripción y categoría'
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Validar código de barras antes de guardar
      final barcode = _barcodeController.text.trim();
      if (barcode.isEmpty) {
        throw Exception('El código de barras es requerido');
      }

      // Verificar si el código de barras ya existe (solo para productos nuevos)
      if (widget.product == null) {
        final barcodeExists = await _inventoryService.isBarcodeExists(barcode);
        if (barcodeExists) {
          throw Exception('El código de barras "$barcode" ya está registrado. Por favor, usa un código diferente.');
        }
      }

      String? imageUrl;
      if (_imageFile != null) {
        // En una app real, subirías la imagen a un servidor y obtendrías la URL.
        // Por ahora, solo guardamos la ruta del archivo.
        imageUrl = _imageFile!.path;
      }

      final product = Product(
        id: barcode, // Usar el código de barras como ID
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        wholesalePrice: double.parse(_wholesalePriceController.text),
        retailPrice: double.parse(_retailPriceController.text),
        distributionPrice: double.parse(_distributionPriceController.text),
        quantity: int.parse(_quantityController.text),
        category: _selectedCategory,
        createdAt: widget.product?.createdAt ?? DateTime.now(),
        imageUrl: imageUrl,
        barcode: barcode, // Incluir el código de barras como campo separado
      );

      print('🔍 DEBUG AddProduct: Guardando producto: ${product.name}');
      print('🔍 DEBUG AddProduct: Código de barras: ${product.id}');
      print('🔍 DEBUG AddProduct: Descripción: ${product.description}');
      print('🔍 DEBUG AddProduct: Categoría: ${product.category}');
      print('🔍 DEBUG AddProduct: Cantidad: ${product.quantity}');
      
      if (widget.product == null) {
        print('🔍 DEBUG AddProduct: Agregando nuevo producto');
        await _inventoryService.addProduct(product);
        print('🔍 DEBUG AddProduct: Producto agregado exitosamente');
      } else {
        print('🔍 DEBUG AddProduct: Actualizando producto existente');
        await _inventoryService.updateProduct(product);
        print('🔍 DEBUG AddProduct: Producto actualizado exitosamente');
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Producto agregado exitosamente'
                  : 'Producto actualizado exitosamente',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar el producto: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.product == null ? 'Agregar Producto' : 'Editar Producto',
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              // Navegar de vuelta al dashboard
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Volver al Dashboard',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Sección de vista previa del producto
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vista Previa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _pickImage,
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: _imageFile != null
                                ? FileImage(_imageFile!)
                                : null,
                            child: _imageFile == null
                                ? Icon(Icons.camera_alt,
                                    color: Colors.grey[800])
                                : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.isEmpty
                                    ? 'Nombre del producto'
                                    : _nameController.text,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _selectedCategory,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Información básica
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información Básica',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Producto *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.inventory_2),
                      ),
                      onChanged: (value) => setState(() {}),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El nombre es requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Descripción',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _showDescriptionTemplates,
                          icon: const Icon(Icons.list_alt),
                          tooltip: 'Plantillas Rápidas',
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Categoría *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: _categories.map((category) {
                        return DropdownMenuItem<String>(
                          value: category['name'],
                          child: Row(
                            children: [
                              Icon(category['icon'], size: 20),
                              const SizedBox(width: 8),
                              Text(category['name']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                          _categoryController.text = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            decoration: const InputDecoration(
                              labelText: 'Cantidad *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.numbers),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La cantidad es requerida';
                              }
                              final quantity = int.tryParse(value);
                              if (quantity == null || quantity < 0) {
                                return 'Ingresa una cantidad válida';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            decoration: const InputDecoration(
                              labelText: 'Stock Mínimo',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.warning),
                              hintText: '5',
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                final minStock = int.tryParse(value);
                                if (minStock == null || minStock < 0) {
                                  return 'Stock mínimo inválido';
                                }
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _barcodeController,
                      decoration: InputDecoration(
                        labelText: 'Código de Barras',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.qr_code),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _generateNewBarcode,
                          tooltip: 'Generar nuevo código',
                        ),
                      ),
                      readOnly: _autoGenerateBarcode,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El código de barras es requerido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Precios
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Precios',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          title: const Text('Cálculo Automático'),
                          subtitle: const Text('Calcular precios automáticamente'),
                          value: _autoCalculatePrices,
                          onChanged: (value) {
                            setState(() {
                              _autoCalculatePrices = value;
                            });
                          },
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _wholesalePriceController,
                      decoration: const InputDecoration(
                        labelText: 'Precio al Por Mayor *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.attach_money),
                        suffixText: 'DOP',
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio al por mayor es requerido';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _retailPriceController,
                      decoration: InputDecoration(
                        labelText: 'Precio al Detalle *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: 'DOP',
                        helperText: _autoCalculatePrices 
                            ? 'Calculado automáticamente (+50% margen)'
                            : 'Margen sugerido: +50%',
                        helperStyle: TextStyle(
                          color: _autoCalculatePrices ? Colors.blue[600] : Colors.grey[600],
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio al detalle es requerido';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _distributionPriceController,
                      decoration: InputDecoration(
                        labelText: 'Precio de Distribución *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        suffixText: 'DOP',
                        helperText: _autoCalculatePrices 
                            ? 'Calculado automáticamente (+30% margen)'
                            : 'Margen sugerido: +30%',
                        helperStyle: TextStyle(
                          color: _autoCalculatePrices ? Colors.blue[600] : Colors.grey[600],
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'El precio de distribución es requerido';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price < 0) {
                          return 'Ingresa un precio válido';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _saveProduct,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      widget.product == null
                          ? 'Agregar Producto'
                          : 'Actualizar Producto',
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Botón para volver al dashboard
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.dashboard),
                label: const Text('Volver al Dashboard'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}