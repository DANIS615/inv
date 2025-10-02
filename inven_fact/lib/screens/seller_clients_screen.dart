import 'package:flutter/material.dart';
import '../utils/event_bus.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SellerClientsScreen extends StatefulWidget {
  final bool showCreditOnly;
  const SellerClientsScreen({super.key, this.showCreditOnly = false});

  @override
  State<SellerClientsScreen> createState() => _SellerClientsScreenState();
}

class _SellerClientsScreenState extends State<SellerClientsScreen> {
  final ClientService _clientService = ClientService();
  List<Client> _clients = [];
  List<Client> _filteredClients = [];
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _rncController = TextEditingController();
  final _cedulaController = TextEditingController();
  final _direccionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController = TextEditingController();
  bool _isLoading = true;
  AccountType _selectedAccountType = AccountType.contado;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterClients);
    _loadClients();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _rncController.dispose();
    _cedulaController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clients = await _clientService.getClients();
      setState(() {
        _clients = clients;
        _filteredClients = widget.showCreditOnly
            ? clients.where((c) => c.accountType == AccountType.credito).toList()
            : clients;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _clients = [];
        _filteredClients = [];
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar clientes: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _filterClients() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredClients = _clients.where((client) {
        return client.name.toLowerCase().contains(query) ||
               client.code.toLowerCase().contains(query) ||
               (client.rnc?.toLowerCase().contains(query) ?? false) ||
               (client.cedula?.toLowerCase().contains(query) ?? false);
      }).toList();
    });
  }

  /// Genera un código único de 6 dígitos para el cliente
  Future<String> _generateClientCode() async {
    final existingCodes = _clients.map((c) => c.code).toSet();
    String newCode;
    int attempts = 0;
    const maxAttempts = 100;

    do {
      newCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      attempts++;
      if (attempts >= maxAttempts) {
        newCode = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        break;
      }
    } while (existingCodes.contains(newCode));

    return newCode;
  }

  Future<void> _addClient() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre del cliente es requerido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validar código del cliente
    String clientCode = _codeController.text.trim();
    // Sanear: dejar solo dígitos
    clientCode = clientCode.replaceAll(RegExp(r'\D'), '');

    if (clientCode.isEmpty) {
      clientCode = await _generateClientCode();
      setState(() {
        _codeController.text = clientCode;
      });
    } else if (!RegExp(r'^\d{6}$').hasMatch(clientCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código debe tener exactamente 6 dígitos numéricos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar duplicados
    final duplicate = _clients.any((c) => c.code == clientCode);
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un cliente con este código. Genera otro.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final client = Client(
        name: _nameController.text.trim(),
        code: clientCode,
        accountType: _selectedAccountType,
        pendingBalance: 0.0,
        lastPurchase: null,
        isActive: true,
        rnc: _rncController.text.trim().isNotEmpty ? _rncController.text.trim() : null,
        cedula: _cedulaController.text.trim().isNotEmpty ? _cedulaController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );

      await _clientService.addClient(client);
      // Notificar dashboard
      try { await Future.microtask(() => EventBus().fire('clientsChanged')); } catch (_) {}
      
      // Limpiar campos
      _nameController.clear();
      _codeController.clear();
      _rncController.clear();
      _cedulaController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _selectedAccountType = AccountType.contado;

      // Recargar lista
      await _loadClients();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cliente agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al agregar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddClientDialog() {
    // Preparar valores iniciales
    _nameController.clear();
    _codeController.clear();
    _rncController.clear();
    _cedulaController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _selectedAccountType = AccountType.contado;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          title: const Text('Agregar Nuevo Cliente'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Código del Cliente destacado
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Código del Cliente (6 dígitos)',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: '123456',
                            prefixIcon: const Icon(Icons.qr_code),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                final newCode = await _generateClientCode();
                                setState(() {
                                  _codeController.text = newCode;
                                });
                              },
                              tooltip: 'Generar nuevo código',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    value: _selectedAccountType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cuenta',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: AccountType.contado, child: Text('Contado')),
                      DropdownMenuItem(value: AccountType.credito, child: Text('Crédito')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rncController,
                    decoration: const InputDecoration(
                      labelText: 'RNC (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cedulaController,
                    decoration: const InputDecoration(
                      labelText: 'Cédula (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: _addClient,
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditClientDialog(Client client) {
    // Prellenar controles con datos del cliente
    _nameController.text = client.name;
    _codeController.text = client.code;
    _rncController.text = client.rnc ?? '';
    _cedulaController.text = client.cedula ?? '';
    _direccionController.text = client.direccion ?? '';
    _telefonoController.text = client.telefono ?? '';
    _emailController.text = client.email ?? '';
    _selectedAccountType = client.accountType;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          title: const Text('Editar Cliente'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.qr_code, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            Text(
                              'Código del Cliente (6 dígitos)',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _codeController,
                          decoration: InputDecoration(
                            hintText: '123456',
                            prefixIcon: const Icon(Icons.qr_code),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: () async {
                                final newCode = await _generateClientCode();
                                setState(() {
                                  _codeController.text = newCode;
                                });
                              },
                              tooltip: 'Generar nuevo código',
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Cliente *',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<AccountType>(
                    value: _selectedAccountType,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Cuenta',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: AccountType.contado, child: Text('Contado')),
                      DropdownMenuItem(value: AccountType.credito, child: Text('Crédito')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _rncController,
                    decoration: const InputDecoration(
                      labelText: 'RNC (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _cedulaController,
                    decoration: const InputDecoration(
                      labelText: 'Cédula (opcional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _telefonoController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email (opcional)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Validar nombre
                if (_nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre del cliente es requerido'), backgroundColor: Colors.red),
                  );
                  return;
                }
                // Validar código único 6 dígitos
                String newCode = _codeController.text.trim().replaceAll(RegExp(r'\D'), '');
                if (!RegExp(r'^\d{6}$').hasMatch(newCode)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El código debe tener exactamente 6 dígitos numéricos'), backgroundColor: Colors.red),
                  );
                  return;
                }
                final duplicate = _clients.any((c) => c.code == newCode && c.id != client.id);
                if (duplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ya existe un cliente con este código. Elige otro.'), backgroundColor: Colors.red),
                  );
                  return;
                }

                try {
                  final updated = client.copyWith(
                    name: _nameController.text.trim(),
                    code: newCode,
                    accountType: _selectedAccountType,
                    rnc: _rncController.text.trim().isNotEmpty ? _rncController.text.trim() : null,
                    cedula: _cedulaController.text.trim().isNotEmpty ? _cedulaController.text.trim() : null,
                    direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
                    telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
                    email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
                  );

                  if (updated.id != null) {
                    await _clientService.updateClient(updated);
                  } else {
                    await _clientService.updateClientByCode(updated);
                  }
                  try { EventBus().fire('clientsChanged'); } catch (_) {}
                  await _loadClients();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cliente actualizado'), backgroundColor: Colors.green),
                    );
                    Navigator.of(context).pop();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al actualizar: $e'), backgroundColor: Colors.red),
                    );
                  }
                }
              },
              child: const Text('Guardar Cambios'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: client.accountType == AccountType.credito ? Colors.orange : Colors.green,
          child: Text(
            client.name[0].toUpperCase(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Código: ${client.code}'),
            Text('Tipo: ${client.accountType == AccountType.credito ? 'Crédito' : 'Contado'}'),
            if (client.accountType == AccountType.credito && client.pendingBalance > 0)
              Text(
                'Saldo pendiente: RD\$${client.pendingBalance.toStringAsFixed(2)}',
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            if (client.rnc != null || client.cedula != null) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  if (client.rnc != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.business, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'RNC: ${client.rnc}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (client.cedula != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'Cédula: ${client.cedula}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'print_barcode',
              child: Row(
                children: [
                  Icon(Icons.qr_code, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Imprimir Código', style: TextStyle(color: Colors.blue)),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _showEditClientDialog(client);
            } else if (value == 'print_barcode') {
              _printClientBarcode(client);
            } else if (value == 'delete') {
              _showDeleteClientDialog(client);
            }
          },
        ),
        onTap: () {
          // Navegar a información del cliente o crear factura
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente seleccionado: ${client.name}'),
              action: SnackBarAction(
                label: 'Crear Factura',
                onPressed: () {
                  // TODO: Navegar a crear factura
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No se encontraron clientes',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otros términos de búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                _filterClients();
              },
              icon: const Icon(Icons.clear),
              label: const Text('Limpiar Búsqueda'),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No hay clientes registrados',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega tu primer cliente para empezar',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddClientDialog,
            icon: const Icon(Icons.person_add),
            label: const Text('Agregar Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Clientes'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _ClientSearchDelegate(_clients),
              );
            },
            tooltip: 'Buscar',
          ),
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Volver al Dashboard',
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterClients();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredClients.length,
                        itemBuilder: (context, index) {
                          return _buildClientCard(_filteredClients[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddClientDialog,
        child: const Icon(Icons.person_add),
      ),
    );
  }

  void _showDeleteClientDialog(Client client) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar Cliente'),
          content: Text('¿Estás seguro de que quieres eliminar a "${client.name}"?\n\nEsta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteClient(client);
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

  Future<void> _deleteClient(Client client) async {
    try {
      if (client.id != null) {
        await _clientService.deleteClient(client.id!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente "${client.name}" eliminado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
          _loadClients();
        }
      } else {
        throw Exception('ID de cliente no válido');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _printClientBarcode(Client client) async {
    try {
      // Mostrar diálogo de confirmación
      final shouldPrint = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.qr_code, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(
                child: Text('Imprimir Código de Cliente'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cliente: ${client.name}'),
              Text('Código: ${client.code}'),
              const SizedBox(height: 16),
              const Text(
                'Se imprimirá un ticket con el código de barras del cliente para que pueda escanearlo fácilmente.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.print),
              label: const Text('Imprimir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );

      if (shouldPrint != true) return;

      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Imprimiendo código de cliente...')),
            ],
          ),
        ),
      );

      // Obtener información de la empresa
      final prefs = await SharedPreferences.getInstance();
      final String companyName = prefs.getString('companyName') ?? 'Mi Empresa';
      final String companyPhone = prefs.getString('companyPhone') ?? '809-123-4567';

      // Inicializar impresora
      await SunmiPrinter.initPrinter();

      // Header
      await SunmiPrinter.printText(companyName);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Tel: $companyPhone');
      await SunmiPrinter.lineWrap(2);

      // Título
      await SunmiPrinter.printText('CODIGO QR DE CLIENTE');
      await SunmiPrinter.lineWrap(2);

      // Información del cliente
      await SunmiPrinter.printText('Cliente: ${client.name}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Codigo: ${client.code}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Tipo: ${client.accountType == AccountType.credito ? 'Credito' : 'Contado'}');
      await SunmiPrinter.lineWrap(2);

      // Código del cliente (formato texto para escáner QR)
      await SunmiPrinter.printText('--------------------------------');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('CODIGO DE CLIENTE:');
      await SunmiPrinter.lineWrap(2);
      
      // Imprimir el código de barras del cliente
      print('DEBUG: Código del cliente: "${client.code}"');
      await SunmiPrinter.printBarCode(client.code);
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('--------------------------------');
      await SunmiPrinter.lineWrap(2);

      // Instrucciones
      await SunmiPrinter.printText('INSTRUCCIONES:');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('1. Escanee este codigo para');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('   acceder a su cuenta');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('2. Guarde este ticket');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('3. Presentelo al hacer compras');
      await SunmiPrinter.lineWrap(3);

      // Footer
      await SunmiPrinter.printText('Gracias por su preferencia!');
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();

      // Cerrar diálogo de carga
      if (mounted) Navigator.of(context).pop();

      // Mostrar éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código de barras impreso para ${client.name}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Imprimir Otro',
              onPressed: () => _printClientBarcode(client),
            ),
          ),
        );
      }

    } catch (e) {
      // Cerrar diálogo de carga si está abierto
      if (mounted) Navigator.of(context).pop();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir código: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ClientSearchDelegate extends SearchDelegate<Client?> {
  final List<Client> clients;

  _ClientSearchDelegate(this.clients);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredClients = clients.where((client) {
      return client.name.toLowerCase().contains(query.toLowerCase()) ||
             client.code.toLowerCase().contains(query.toLowerCase()) ||
             (client.rnc?.toLowerCase().contains(query.toLowerCase()) ?? false) ||
             (client.cedula?.toLowerCase().contains(query.toLowerCase()) ?? false);
    }).toList();

    return ListView.builder(
      itemCount: filteredClients.length,
      itemBuilder: (context, index) {
        final client = filteredClients[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: client.accountType == AccountType.credito ? Colors.orange : Colors.green,
            child: Text(
              client.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(client.name),
          subtitle: Text('Código: ${client.code}'),
          onTap: () {
            close(context, client);
          },
        );
      },
    );
  }
}
