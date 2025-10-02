import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/client_service.dart';
import '../services/client_context_service.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientService _clientService = ClientService();
  final ClientContextService _clientContext = ClientContextService();
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
      // No necesitamos establecer contexto ya que el servicio funciona sin cliente activo
    final clients = await _clientService.getClients();
    setState(() {
      _clients = clients;
        _filteredClients = clients;
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
            client.code.toLowerCase().contains(query);
      }).toList();
    });
  }

  /// Genera un código único de 6 dígitos para el cliente
  Future<String> _generateClientCode() async {
    // Obtener todos los códigos existentes
    final existingCodes = _clients.map((client) => client.code).toSet();
    
    String newCode;
    int attempts = 0;
    const maxAttempts = 100;
    
    do {
      // Generar código aleatorio de 6 dígitos
      newCode = (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
      attempts++;
      
      if (attempts >= maxAttempts) {
        // Si no se puede generar un código único, usar timestamp
        newCode = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
        break;
      }
    } while (existingCodes.contains(newCode));
    
    print('🔍 DEBUG: Código generado para cliente: $newCode');
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
    if (clientCode.isEmpty) {
      // Generar código automáticamente si está vacío
      clientCode = await _generateClientCode();
      setState(() {
        _codeController.text = clientCode;
      });
    } else if (clientCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código del cliente debe tener exactamente 6 dígitos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    } else if (!RegExp(r'^\d{6}$').hasMatch(clientCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El código del cliente solo puede contener números'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Verificar que el código no esté duplicado
    final existingClient = _clients.where((client) => client.code == clientCode).isNotEmpty;
    if (existingClient) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ya existe un cliente con este código. Use el botón de refresh para generar uno nuevo'),
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
        rnc: _rncController.text.trim().isNotEmpty ? _rncController.text.trim() : null,
        cedula: _cedulaController.text.trim().isNotEmpty ? _cedulaController.text.trim() : null,
        direccion: _direccionController.text.trim().isNotEmpty ? _direccionController.text.trim() : null,
        telefono: _telefonoController.text.trim().isNotEmpty ? _telefonoController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );
      
      await _clientService.addClient(client);
      
      _nameController.clear();
      _codeController.clear();
      _rncController.clear();
      _cedulaController.clear();
      _direccionController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _loadClients();
      
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cliente ${client.name} agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
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

  Future<void> _showAddClientDialog() async {
    _nameController.clear();
    _codeController.clear();
    _rncController.clear();
    _cedulaController.clear();
    _direccionController.clear();
    _telefonoController.clear();
    _emailController.clear();
    _selectedAccountType = AccountType.contado;
    
    // Generar código automáticamente al abrir el modal
    final newCode = await _generateClientCode();
    _codeController.text = newCode;

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              contentPadding: const EdgeInsets.all(16),
              title: const Text('➕ AGREGAR NUEVO CLIENTE'),
              content: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360, maxHeight: 520),
                child: SizedBox(
                  width: double.maxFinite,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // CÓDIGO DEL CLIENTE - MUY DESTACADO
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue, width: 2),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.qr_code, color: Colors.blue[800], size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    'CÓDIGO DEL CLIENTE (6 DÍGITOS)',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[800],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _codeController,
                                decoration: InputDecoration(
                                  hintText: '123456',
                                  prefixIcon: const Icon(Icons.qr_code, color: Colors.blue),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.refresh, color: Colors.blue),
                                    onPressed: () async {
                                      final newCode = await _generateClientCode();
                                      setState(() {
                                        _codeController.text = newCode;
                                      });
                                    },
                                    tooltip: 'Generar nuevo código',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(color: Colors.blue, width: 2),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Nombre del cliente
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del Cliente *',
                            hintText: 'Ej: Juan Pérez',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: 12),
                        
                        // Tipo de cuenta
                        DropdownButtonFormField<AccountType>(
                          value: _selectedAccountType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de Cuenta *',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: AccountType.contado,
                              child: Text('Contado'),
                            ),
                            DropdownMenuItem(
                              value: AccountType.credito,
                              child: Text('Crédito'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _selectedAccountType = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        
                        // RNC
                        TextField(
                          controller: _rncController,
                          decoration: const InputDecoration(
                            labelText: 'RNC (Opcional)',
                            hintText: '123456789',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Cédula
                        TextField(
                          controller: _cedulaController,
                          decoration: const InputDecoration(
                            labelText: 'Cédula (Opcional)',
                            hintText: '12345678901',
                            prefixIcon: Icon(Icons.badge),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Teléfono
                        TextField(
                          controller: _telefonoController,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono (Opcional)',
                            hintText: '809-123-4567',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // Email
                        TextField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email (Opcional)',
                            hintText: 'cliente@email.com',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 12),
                        
                        // Dirección
                        TextField(
                          controller: _direccionController,
                          decoration: const InputDecoration(
                            labelText: 'Dirección (Opcional)',
                            hintText: 'Calle Principal #123',
                            prefixIcon: Icon(Icons.location_on),
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                      ],
                    ),
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Agregar Cliente'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).primaryColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
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
            icon: const Icon(Icons.refresh),
            onPressed: _loadClients,
            tooltip: 'Actualizar',
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar clientes...',
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
          ),
          
          // Lista de clientes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredClients.isEmpty
                    ? _buildEmptyState()
                    : _buildClientsList(),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "dashboard",
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            backgroundColor: Colors.orange,
            child: const Icon(Icons.dashboard),
            tooltip: 'Volver al Dashboard',
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "add",
            onPressed: _showAddClientDialog,
            child: const Icon(Icons.add),
            tooltip: 'Agregar Cliente',
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final bool isSearching = _searchController.text.isNotEmpty;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isSearching 
                    ? Colors.orange.withOpacity(0.1)
                    : Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSearching ? Icons.search_off : Icons.people_outline,
                size: 80,
                color: isSearching 
                    ? Colors.orange[600]
                    : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isSearching
                  ? 'No se encontraron clientes'
                  : '¡Agrega tu primer cliente!',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: isSearching 
                    ? Colors.orange[600]
                    : Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              isSearching
                  ? 'Intenta con otra búsqueda o agrega un nuevo cliente'
                  : 'Comienza a gestionar tu base de clientes.\nAgrega información completa incluyendo RNC, cédula y datos de contacto.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showAddClientDialog,
              icon: const Icon(Icons.person_add, size: 20),
              label: Text(isSearching ? 'Agregar Cliente' : 'Agregar Primer Cliente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  // TODO: Implementar importar clientes
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de importar próximamente disponible'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Importar desde Excel'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
            if (isSearching) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  _searchController.clear();
                },
                icon: const Icon(Icons.clear, size: 18),
                label: const Text('Limpiar búsqueda'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildClientsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredClients.length,
      itemBuilder: (context, index) {
        final client = _filteredClients[index];
        return _buildClientCard(client);
      },
    );
  }

  Widget _buildClientCard(Client client) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: client.accountType == AccountType.credito 
              ? Colors.blue[100] 
              : Colors.green[100],
          child: Icon(
            client.accountType == AccountType.credito 
                ? Icons.account_balance_wallet 
                : Icons.payment,
            color: client.accountType == AccountType.credito 
                ? Colors.blue[700] 
                : Colors.green[700],
          ),
        ),
        title: Text(
          client.name,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Código: ${client.code}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  client.accountType == AccountType.credito 
                      ? Icons.account_balance_wallet 
                      : Icons.payment,
                  size: 16,
                  color: client.accountType == AccountType.credito 
                      ? Colors.blue[700] 
                      : Colors.green[700],
                ),
                const SizedBox(width: 4),
                Text(
                  client.accountType == AccountType.credito ? 'Crédito' : 'Contado',
                  style: TextStyle(
                    color: client.accountType == AccountType.credito 
                        ? Colors.blue[700] 
                        : Colors.green[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (client.accountType == AccountType.credito && client.pendingBalance > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Saldo: RD\$${client.pendingBalance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[700],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            if (client.direccion != null || client.telefono != null) ...[
              const SizedBox(height: 8),
              if (client.direccion != null) ...[
                Row(
                  children: [
                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        client.direccion!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (client.telefono != null) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.phone, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      client.telefono!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ],
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
        trailing: PopupMenuButton<String>(
          onSelected: (value) {
            switch (value) {
              case 'edit':
                // TODO: Implementar edición
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edición en desarrollo')),
                );
                break;
              case 'delete':
                _showDeleteConfirmation(client);
                break;
            }
          },
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
        ),
      ),
    );
  }

  void _showDeleteConfirmation(Client client) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: Text('¿Estás seguro de que quieres eliminar al cliente "${client.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              // TODO: Implementar eliminación
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Eliminación en desarrollo')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}