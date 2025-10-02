import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompanySettingsScreen extends StatefulWidget {
  const CompanySettingsScreen({super.key});

  @override
  State<CompanySettingsScreen> createState() => _CompanySettingsScreenState();
}

class _CompanySettingsScreenState extends State<CompanySettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _rncController = TextEditingController();
  final _branchController = TextEditingController();
  final _emailController = TextEditingController();
  
  bool _isLoading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _loadCompanyData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _rncController.dispose();
    _branchController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadCompanyData() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('companyName') ?? '';
      _addressController.text = prefs.getString('companyAddress') ?? '';
      _phoneController.text = prefs.getString('companyPhone') ?? '';
      _rncController.text = prefs.getString('companyRNC') ?? '';
      _branchController.text = prefs.getString('branch') ?? '';
      _emailController.text = prefs.getString('companyEmail') ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCompanyData() async {
    if (!_formKey.currentState!.validate()) return;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('companyName', _nameController.text);
    await prefs.setString('companyAddress', _addressController.text);
    await prefs.setString('companyPhone', _phoneController.text);
    await prefs.setString('companyRNC', _rncController.text);
    await prefs.setString('branch', _branchController.text);
    await prefs.setString('companyEmail', _emailController.text);

    setState(() {
      _isEditing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Configuración de empresa actualizada'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: Theme.of(context).primaryColor,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        subtitle: Text(
          value.isEmpty ? 'No configurado' : value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: value.isEmpty ? Colors.red[600] : Colors.grey[800],
          ),
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Nombre de la Empresa',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.business),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el nombre de la empresa';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Correo Electrónico',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el correo electrónico';
              }
              if (!value.contains('@') || !value.contains('.')) {
                return 'Ingrese un correo electrónico válido';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Dirección',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_on),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la dirección';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Teléfono',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.phone),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el teléfono';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _rncController,
            decoration: const InputDecoration(
              labelText: 'RNC',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.assignment),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese el RNC';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _branchController,
            decoration: const InputDecoration(
              labelText: 'Sucursal',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.store),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Por favor ingrese la sucursal';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildViewMode() {
    return Column(
      children: [
        _buildInfoCard('Nombre de la Empresa', _nameController.text, Icons.business),
        _buildInfoCard('Correo Electrónico', _emailController.text, Icons.email),
        _buildInfoCard('Dirección', _addressController.text, Icons.location_on),
        _buildInfoCard('Teléfono', _phoneController.text, Icons.phone),
        _buildInfoCard('RNC', _rncController.text, Icons.assignment),
        _buildInfoCard('Sucursal', _branchController.text, Icons.store),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuración de Empresa'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_isEditing && !_isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              tooltip: 'Editar',
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header informativo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).primaryColor.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Esta información aparecerá en todas las facturas impresas',
                            style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Contenido principal
                  _isEditing ? _buildEditForm() : _buildViewMode(),
                  
                  const SizedBox(height: 32),
                  
                  // Botones de acción
                  if (_isEditing) ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _isEditing = false;
                              });
                              _loadCompanyData(); // Recargar datos originales
                            },
                            child: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saveCompanyData,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text('Guardar Cambios', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Editar Información'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
