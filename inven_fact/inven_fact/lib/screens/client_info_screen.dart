import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../services/client_context_service.dart';
import '../services/client_service.dart';
import 'home_screen.dart';
import 'invoice_screen.dart';
import 'client_catalog_screen.dart';
import 'payment_history_screen.dart';
import '../services/payment_service.dart';
import '../models/payment.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import 'client_invoice_screen.dart';
import '../utils/event_bus.dart';
import 'welcome_screen.dart';

class ClientInfoScreen extends StatefulWidget {
  final String clientCode;

  const ClientInfoScreen({
    super.key,
    required this.clientCode,
  });

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen> {
  final ClientContextService _clientContext = ClientContextService();
  Client? _client;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientInfo();
  }

  Future<void> _loadClientInfo() async {
    try {
      // Primero intentar obtener el cliente de la base de datos SQLite
      final clientService = ClientService();
      Client? client = await clientService.getClientByCode(widget.clientCode);
      
      if (client != null) {
        // Cliente encontrado en la base de datos del vendedor
        setState(() {
          _client = client;
          _isLoading = false;
        });
      } else {
        // Cliente no encontrado en la base de datos SQLite
        setState(() {
          _client = null;
          _isLoading = false;
        });
        
        // Mostrar error y regresar a la pantalla anterior
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente con código "${widget.clientCode}" no encontrado. Contacta al vendedor para registrarte.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          
          // Regresar a la pantalla anterior
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar información del cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Métodos de simulación - en producción vendrían de la base de datos
  AccountType _getRandomAccountType() {
    // Simular 70% contado, 30% crédito
    return DateTime.now().millisecond % 10 < 7 
        ? AccountType.contado 
        : AccountType.credito;
  }

  double _getRandomBalance() {
    if (_getRandomAccountType() == AccountType.contado) return 0.0;
    // Simular saldo entre 0 y 5000
    return (DateTime.now().millisecond % 5000).toDouble();
  }

  DateTime? _getRandomLastPurchase() {
    // Simular última compra entre 0 y 30 días atrás
    final daysAgo = DateTime.now().millisecond % 30;
    return DateTime.now().subtract(Duration(days: daysAgo));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cliente: ${widget.clientCode}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: changeClient,
          tooltip: 'Cambiar Cliente',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: changeClient,
            tooltip: 'Volver al Inicio',
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildLoadingState()
          : _client == null
              ? _buildErrorState()
              : _buildClientInfo(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Cargando información del cliente...',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.red[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 50,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Cliente No Encontrado',
              style: TextStyle(
                fontSize: 20,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'El código de cliente "${widget.clientCode}" no está registrado en el sistema.\n\nVerifica el código e intenta nuevamente, o contacta al vendedor para registrarte.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadClientInfo();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: changeClient,
                  icon: const Icon(Icons.home),
                  label: const Text('Volver al Inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header con gradiente
          _buildGradientHeader(),
          
          // Contenido principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Información general consolidada
                _buildGeneralInfoCard(),
                
                const SizedBox(height: 30),
                
                // Botones de acción
                _buildActionButtons(),
                
                const SizedBox(height: 20),
                
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientHeader() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColor.withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Avatar con iniciales
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _client!.name.isNotEmpty 
                        ? _client!.name[0].toUpperCase()
                        : 'C',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Nombre del cliente
              Text(
                _client!.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Código del cliente
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Código: ${_client!.code}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Badge de estado
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _client!.isActive ? Colors.green : Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _client!.isActive ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _client!.isActive ? 'Activo' : 'Inactivo',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralInfoCard() {
    final isCredito = _client!.accountType == AccountType.credito;
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título de la sección
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información General',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Información básica en dos columnas
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Columna izquierda
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCompactInfoRow(
                        icon: Icons.badge,
                        label: 'Código',
                        value: _client!.code,
                        valueColor: Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 12),
                      
                      _buildCompactInfoRow(
                        icon: Icons.person_outline,
                        label: 'Nombre',
                        value: _client!.name,
                        valueColor: Colors.grey[700],
                      ),
                      const SizedBox(height: 12),
                      
                      // Tipo de cuenta con color distintivo (evita overflow usando Wrap)
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Icon(
                            isCredito ? Icons.credit_card : Icons.account_balance_wallet,
                            color: isCredito ? Colors.orange[700] : Colors.green[700],
                            size: 18,
                          ),
                          Text(
                            'Tipo: ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isCredito ? Colors.orange[50] : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isCredito ? Colors.orange[200]! : Colors.green[200]!,
                              ),
                            ),
                            child: Text(
                              isCredito ? 'Crédito' : 'Contado',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isCredito ? Colors.orange[700] : Colors.green[700],
                              ),
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 20),
                
                // Columna derecha
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Saldo pendiente (solo para crédito)
                      if (isCredito) ...[
                        _buildCompactInfoRow(
                          icon: Icons.monetization_on,
                          label: 'Saldo Pendiente',
                          value: 'RD\$${_client!.pendingBalance.toStringAsFixed(2)}',
                          valueColor: _client!.pendingBalance > 0 ? Colors.red[700] : Colors.green[700],
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Última compra
                      if (_client!.lastPurchase != null) ...[
                        _buildCompactInfoRow(
                          icon: Icons.shopping_cart,
                          label: 'Última Compra',
                          value: _formatDate(_client!.lastPurchase!),
                          valueColor: Colors.grey[700],
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // Estado
                      _buildCompactInfoRow(
                        icon: _client!.isActive ? Icons.check_circle : Icons.cancel,
                        label: 'Estado',
                        value: _client!.isActive ? 'Activo' : 'Inactivo',
                        valueColor: _client!.isActive ? Colors.green[700] : Colors.red[700],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Información adicional en una fila compacta
            if (_client!.rnc != null || _client!.cedula != null || _client!.telefono != null || _client!.email != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (_client!.rnc != null)
                    _buildCompactChip(Icons.business, 'RNC', _client!.rnc!),
                  if (_client!.cedula != null)
                    _buildCompactChip(Icons.credit_card, 'Cédula', _client!.cedula!),
                  if (_client!.telefono != null)
                    _buildCompactChip(Icons.phone, 'Teléfono', _client!.telefono!),
                  if (_client!.email != null)
                    _buildCompactChip(Icons.email, 'Email', _client!.email!),
                  if (_client!.direccion != null)
                    _buildCompactChip(Icons.location_on, 'Dirección', _client!.direccion!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 16,
        ),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? Colors.grey[800],
            ),
            overflow: TextOverflow.ellipsis,
            softWrap: false,
          ),
        ),
      ],
    );
  }

  Widget _buildCompactChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            '$label: $value',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Theme.of(context).primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información Personal',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Información básica
            _buildInfoRow(
              icon: Icons.badge,
              label: 'Código',
              value: _client!.code,
              valueColor: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Nombre',
              value: _client!.name,
              valueColor: Colors.grey[700],
            ),
            const SizedBox(height: 16),
            
            // Información adicional si está disponible
            if (_client!.rnc != null) ...[
              _buildInfoRow(
                icon: Icons.business,
                label: 'RNC',
                value: _client!.rnc!,
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            if (_client!.cedula != null) ...[
              _buildInfoRow(
                icon: Icons.credit_card,
                label: 'Cédula',
                value: _client!.cedula!,
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            if (_client!.telefono != null) ...[
              _buildInfoRow(
                icon: Icons.phone,
                label: 'Teléfono',
                value: _client!.telefono!,
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            if (_client!.email != null) ...[
              _buildInfoRow(
                icon: Icons.email,
                label: 'Email',
                value: _client!.email!,
                valueColor: Colors.grey[700],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeCard() {
    final isCredito = _client!.accountType == AccountType.credito;
    final cardColor = isCredito ? Colors.orange[50] : Colors.green[50];
    final iconColor = isCredito ? Colors.orange[700] : Colors.green[700];
    final borderColor = isCredito ? Colors.orange[200] : Colors.green[200];
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor!, width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor!.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCredito ? Icons.credit_card : Icons.account_balance_wallet,
                    color: iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Tipo de Cuenta',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Tipo de cuenta con estilo especial
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(
                    isCredito ? Icons.credit_card : Icons.payment,
                    color: iconColor,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isCredito ? 'Crédito' : 'Contado',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: iconColor,
                        ),
                      ),
                      Text(
                        isCredito ? 'Puede comprar a crédito' : 'Pago inmediato',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Saldo pendiente para crédito
            if (isCredito) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _client!.pendingBalance > 0 ? Colors.red[50] : Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _client!.pendingBalance > 0 ? Colors.red[200]! : Colors.green[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _client!.pendingBalance > 0 ? Icons.warning : Icons.check_circle,
                      color: _client!.pendingBalance > 0 ? Colors.red[700] : Colors.green[700],
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Pendiente',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'RD\$${_client!.pendingBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _client!.pendingBalance > 0 ? Colors.red[700] : Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdditionalInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Información Adicional',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Última compra
            if (_client!.lastPurchase != null) ...[
              _buildInfoRow(
                icon: Icons.shopping_cart,
                label: 'Última Compra',
                value: _formatDate(_client!.lastPurchase!),
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            // Dirección si está disponible
            if (_client!.direccion != null) ...[
              _buildInfoRow(
                icon: Icons.location_on,
                label: 'Dirección',
                value: _client!.direccion!,
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            // Estado de la cuenta
            _buildInfoRow(
              icon: _client!.isActive ? Icons.check_circle : Icons.cancel,
              label: 'Estado de la Cuenta',
              value: _client!.isActive ? 'Activo' : 'Inactivo',
              valueColor: _client!.isActive ? Colors.green[700] : Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfo() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Información de la Cuenta',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).primaryColor,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Tipo de cuenta
            _buildInfoRow(
              icon: Icons.account_balance_wallet,
              label: 'Tipo de Cuenta',
              value: _client!.accountType == AccountType.contado ? 'Contado' : 'Crédito',
              valueColor: _client!.accountType == AccountType.contado 
                  ? Colors.green[700] 
                  : Colors.blue[700],
            ),
            
            const SizedBox(height: 16),
            
            // Saldo pendiente (solo para crédito)
            if (_client!.accountType == AccountType.credito) ...[
              _buildInfoRow(
                icon: Icons.monetization_on,
                label: 'Saldo Pendiente',
                value: 'RD\$${_client!.pendingBalance.toStringAsFixed(2)}',
                valueColor: _client!.pendingBalance > 0 
                    ? Colors.orange[700] 
                    : Colors.green[700],
              ),
              const SizedBox(height: 16),
            ],
            
            // Última compra
            if (_client!.lastPurchase != null) ...[
              _buildInfoRow(
                icon: Icons.shopping_cart,
                label: 'Última Compra',
                value: _formatDate(_client!.lastPurchase!),
                valueColor: Colors.grey[700],
              ),
              const SizedBox(height: 16),
            ],
            
            // Estado de la cuenta
            _buildInfoRow(
              icon: _client!.isActive ? Icons.check_circle : Icons.cancel,
              label: 'Estado',
              value: _client!.isActive ? 'Activo' : 'Inactivo',
              valueColor: _client!.isActive ? Colors.green[700] : Colors.red[700],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: Theme.of(context).primaryColor,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Botón Facturar (siempre visible) - Diseño principal
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).primaryColor,
                Theme.of(context).primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton.icon(
            onPressed: _navigateToInvoice,
            icon: const Icon(Icons.receipt_long, size: 24),
            label: const Text(
              'Facturar Productos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Botones específicos para crédito
        if (_client!.accountType == AccountType.credito) ...[
          
          // Pagar Cuenta (solo si hay saldo pendiente)
          if (_client!.pendingBalance > 0) ...[
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange[600]!,
                    Colors.orange[500]!,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _payAccount,
                icon: const Icon(Icons.payment, size: 24),
                label: Text(
                  'Pagar Cuenta (RD\$${_client!.pendingBalance.toStringAsFixed(2)})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          const SizedBox(height: 16),
        ],
        
        // Historial de Pagos (para todos los clientes)
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.purple[300]!, width: 2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: OutlinedButton.icon(
            onPressed: _viewPaymentHistory,
            icon: Icon(Icons.history, color: Colors.purple[700], size: 24),
            label: Text(
              'Historial de Facturas',
              style: TextStyle(
                color: Colors.purple[700],
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.purple[50],
              padding: const EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
      ],
    );
  }

  /// Función para cambiar de cliente - regresa a la pantalla de bienvenida
  Future<void> changeClient() async {
    try {
      // Limpiar el contexto del cliente actual (logout)
      await _clientContext.logout();
      
      if (mounted) {
        // Usar exactamente el mismo método que usa welcome_screen para navegar aquí
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const WelcomeScreen(),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR al cambiar cliente: $e');
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;
    
    if (difference == 0) {
      return 'Hoy';
    } else if (difference == 1) {
      return 'Ayer';
    } else if (difference < 7) {
      return 'Hace $difference días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _navigateToInvoice() {
    // Navegar a la facturación manteniendo la pila de navegación
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ClientInvoiceScreen(
          clientCode: widget.clientCode,
        ),
      ),
    );
  }


  void _payAccount() {
    final paymentService = PaymentService();
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController refCtrl = TextEditingController();
    PaymentMethod method = PaymentMethod.cash;
    final BuildContext rootContext = context;

    showDialog(
      context: rootContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pagar Cuenta'),
        content: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(dialogContext).size.height * 0.6),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            Text('Saldo pendiente: RD\$${_client!.pendingBalance.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monto a pagar',
                border: OutlineInputBorder(),
                prefixText: 'RD\$ ',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<PaymentMethod>(
              value: method,
              isExpanded: true,
              items: const [
                DropdownMenuItem(value: PaymentMethod.cash, child: Text('Efectivo')),
                DropdownMenuItem(value: PaymentMethod.transfer, child: Text('Transferencia')),
                DropdownMenuItem(value: PaymentMethod.check, child: Text('Cheque')),
                DropdownMenuItem(value: PaymentMethod.creditCard, child: Text('Tarjeta Crédito')),
                DropdownMenuItem(value: PaymentMethod.debitCard, child: Text('Tarjeta Débito')),
                DropdownMenuItem(value: PaymentMethod.mobilePayment, child: Text('Pago Móvil')),
                DropdownMenuItem(value: PaymentMethod.other, child: Text('Otro')),
              ],
              onChanged: (v) => method = v ?? PaymentMethod.cash,
              decoration: const InputDecoration(labelText: 'Método', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: refCtrl,
              decoration: const InputDecoration(
                labelText: 'Referencia (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountCtrl.text) ?? 0;
              if (amount <= 0 || amount > _client!.pendingBalance) {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  const SnackBar(content: Text('Monto inválido'), backgroundColor: Colors.red),
                );
                return;
              }

              Navigator.of(dialogContext).pop();
              final result = await paymentService.processPayment(
                clientId: _client!.id.toString(),
                clientCode: _client!.code,
                clientName: _client!.name,
                totalAmount: _client!.pendingBalance,
                paymentAmount: amount,
                paymentType: amount >= _client!.pendingBalance ? PaymentType.full : PaymentType.partial,
                paymentMethod: method,
                description: 'Pago desde Cliente',
                invoiceId: DateTime.now().millisecondsSinceEpoch.toString(),
                reference: refCtrl.text.trim().isNotEmpty ? refCtrl.text.trim() : null,
              );

              if (!mounted) return;
              if (result.success) {
                setState(() {
                  _client = _client!.copyWith(pendingBalance: result.remainingBalance ?? 0);
                });
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text(result.message), backgroundColor: Colors.green),
                );
                if (!mounted) return;
                showDialog(
                  context: rootContext,
                  builder: (successContext) => AlertDialog(
                    title: const Text('Pago exitoso'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pagado: RD\$${amount.toStringAsFixed(2)}'),
                        const SizedBox(height: 6),
                        Text('Saldo restante: RD\$${_client!.pendingBalance.toStringAsFixed(2)}'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(successContext).pop(),
                        child: const Text('Continuar'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          try {
                            await SunmiPrinter.initPrinter();
                            await SunmiPrinter.printText('RECIBO DE PAGO');
                            await SunmiPrinter.lineWrap(1);
                            await SunmiPrinter.printText('Cliente: ${_client!.name}');
                            await SunmiPrinter.lineWrap(1);
                            await SunmiPrinter.printText('Pagado: RD\$${amount.toStringAsFixed(2)}');
                            await SunmiPrinter.lineWrap(1);
                            await SunmiPrinter.printText('Saldo restante: RD\$${_client!.pendingBalance.toStringAsFixed(2)}');
                            await SunmiPrinter.lineWrap(2);
                            await SunmiPrinter.printText('Gracias por su pago');
                            await SunmiPrinter.lineWrap(3);
                            await SunmiPrinter.cutPaper();
                          } catch (_) {}
                          try { EventBus().fire('paymentsChanged'); } catch (_) {}
                          if (Navigator.of(successContext).canPop()) {
                            Navigator.of(successContext).pop();
                          }
                        },
                        child: const Text('Imprimir'),
                      ),
                    ],
                  ),
                );
              } else {
                ScaffoldMessenger.of(rootContext).showSnackBar(
                  SnackBar(content: Text(result.message), backgroundColor: Colors.red),
                );
              }
            },
            child: const Text('Pagar'),
          ),
        ],
      ),
    );
  }

  void _viewPaymentHistory() {
    if (_client != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => PaymentHistoryScreen(
            clientId: _client!.id.toString(),
            clientName: _client!.name,
            clientCode: _client!.code,
            accountType: _client!.accountType,
          ),
        ),
      );
    }
  }
}
