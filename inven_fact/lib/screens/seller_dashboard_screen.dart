import 'package:flutter/material.dart';
import 'dart:async';
import 'home_screen.dart';
import 'clients_screen.dart';
import 'seller_clients_screen.dart';
import 'add_product_screen.dart';
import 'company_screen.dart';
import 'company_settings_screen.dart';
import 'barcode_scanner_screen.dart';
import 'client_info_screen.dart';
import 'inventory_dashboard_screen.dart';
import 'welcome_screen.dart';
import '../services/client_service.dart';
import '../services/inventory_service.dart';
import '../services/dashboard_service.dart';
import '../utils/event_bus.dart';
import '../services/auth_service.dart';
// removed duplicate import
import '../models/client.dart';
import '../models/product.dart';

class SellerDashboardScreen extends StatefulWidget {
  const SellerDashboardScreen({super.key});

  @override
  State<SellerDashboardScreen> createState() => _SellerDashboardScreenState();
}

class _SellerDashboardScreenState extends State<SellerDashboardScreen> {
  int _selectedIndex = 0;
  final AuthService _authService = AuthService();

  List<Widget> get _screens => [
    _DashboardHome(
      onNavigateToHome: _navigateToHome,
      onNavigateToAddProduct: _navigateToAddProduct,
      onNavigateToClients: _navigateToClients,
    ),
    const _QuickActions(),
    const _RecentActivity(),
  ];

  @override
  void initState() {
    super.initState();
    // Refrescar datos cuando se inicializa la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  void _refreshData() {
    // Forzar reconstrucción de los widgets que muestran datos
    setState(() {});
  }

  void _navigateToHome(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InventoryDashboardScreen(),
      ),
    );
    // Refrescar datos cuando se regresa
    _refreshData();
  }

  void _navigateToAddProduct(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const AddProductScreen(),
      ),
    );
    // Refrescar datos cuando se regresa
    _refreshData();
  }

  void _navigateToClients(BuildContext context, {bool creditOnly = false}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SellerClientsScreen(showCreditOnly: creditOnly),
      ),
    );
    // Refrescar datos cuando se regresa
    _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de ${_authService.sellerName ?? 'Vendedor'}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: _scanClientCode,
            tooltip: 'Escanear Cliente',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: 'Configuración',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar Sesión',
          ),
        ],
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Acciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Actividad',
          ),
        ],
      ),
    );
  }

  void _scanClientCode() async {
    try {
      final String? scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      if (scannedCode != null && scannedCode.isNotEmpty) {
        // Navegar a la información del cliente escaneado
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClientInfoScreen(clientCode: scannedCode),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CompanySettingsScreen(),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.logoutSeller();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => WelcomeScreen(),
          ),
          (route) => false,
        );
      }
    }
  }
}

class _DashboardHome extends StatefulWidget {
  final Function(BuildContext) onNavigateToHome;
  final Function(BuildContext) onNavigateToAddProduct;
  final void Function(BuildContext, {bool creditOnly}) onNavigateToClients;

  const _DashboardHome({
    required this.onNavigateToHome,
    required this.onNavigateToAddProduct,
    required this.onNavigateToClients,
  });

  @override
  State<_DashboardHome> createState() => _DashboardHomeState();
}

class _DashboardHomeState extends State<_DashboardHome> {
  final DashboardService _dashboardService = DashboardService();
  StreamSubscription<String>? _eventsSub;
  final AuthService _auth = AuthService();
  DashboardMetrics? _metrics;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _refreshMetrics();
    
    // Escuchar eventos de cambios en la base de datos
    _eventsSub = EventBus().stream.listen((event) {
      if (!mounted) return;
      // Actualizar dashboard cuando detecte cualquier cambio importante
      if (event == 'clientsChanged' || 
          event == 'inventoryChanged' || 
          event == 'paymentsChanged' ||
          event == 'productAdded' ||
          event == 'productUpdated' ||
          event == 'productDeleted' ||
          event == 'clientAdded' ||
          event == 'clientUpdated' ||
          event == 'saleCompleted') {
        _refreshMetrics();
      }
    });
  }

  Future<void> _refreshMetrics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final metrics = await _dashboardService.computeMetrics();
      if (mounted) {
        setState(() {
          _metrics = metrics;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _eventsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = _isLoading || _metrics == null;
    final m = _metrics;

    return RefreshIndicator(
      onRefresh: _refreshMetrics,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            if (isLoading) _buildSkeletonGrid() else _buildStatsGrid(context, m!),
            const SizedBox(height: 24),
            _buildQuickAccess(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final sellerName = _auth.sellerName ?? 'Vendedor';
    return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hola, $sellerName', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text('Resumen de inventario', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[600])),
            ),
            if (_isLoading)
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, DashboardMetrics m) {
    // Formatear valor de inventario
    String formatInventoryValue(double value) {
      if (value >= 1000000) {
        return 'RD\$${(value / 1000000).toStringAsFixed(1)}M';
      } else if (value >= 1000) {
        return 'RD\$${(value / 1000).toStringAsFixed(1)}K';
      } else {
        return 'RD\$${value.toStringAsFixed(0)}';
      }
    }

    final cards = [
      _MetricCardData('Total Clientes', m.totalClients.toString(), Icons.people, Colors.blue, () => widget.onNavigateToClients(context)),
      _MetricCardData('Total Productos', m.totalProducts.toString(), Icons.inventory, Colors.orange, () => widget.onNavigateToHome(context)),
      _MetricCardData('Stock Bajo', m.lowStockProducts.toString(), Icons.warning, Colors.amber, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryDashboardScreen(showLowStock: true)))),
      _MetricCardData('Sin Stock', m.outOfStockProducts.toString(), Icons.error, Colors.red, () => Navigator.of(context).push(MaterialPageRoute(builder: (context) => const InventoryDashboardScreen(showOutOfStock: true)))),
      _MetricCardData('Valor Inventario', formatInventoryValue(m.totalInventoryValue), Icons.attach_money, Colors.green, () => widget.onNavigateToHome(context)),
      _MetricCardData('Clientes Crédito', m.creditClients.toString(), Icons.account_balance_wallet, Colors.purple, () => widget.onNavigateToClients(context, creditOnly: true)),
    ];

    final crossAxisCount = MediaQuery.of(context).size.width > 700 ? 3 : 2;
    final double aspect = MediaQuery.of(context).size.width > 700 ? 1.6 : 1.5;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: cards.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: aspect,
      ),
      itemBuilder: (context, index) {
        final c = cards[index];
        return _buildMetricCard(context, c);
      },
    );
  }

  Widget _buildMetricCard(BuildContext context, _MetricCardData data) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: data.onTap,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [data.color.withOpacity(0.1), data.color.withOpacity(0.02)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: data.color.withOpacity(0.2)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isTight = constraints.maxHeight < 80;
            final double iconSize = isTight ? 14 : 20;
            final double valueSize = data.title == 'Valor Inventario'
                ? (isTight ? 14 : 18)
                : (isTight ? 18 : 24);
            final double labelSize = isTight ? 9 : 12;
            final double spacing = isTight ? 2 : 8;
            final double pad = isTight ? 8 : 16;
            final double hspace = isTight ? 6 : 8;

            return Padding(
              padding: EdgeInsets.all(pad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: data.color.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        padding: EdgeInsets.all(isTight ? 4 : 8),
                        child: Icon(data.icon, color: data.color, size: iconSize),
                      ),
                      SizedBox(width: hspace),
                      Expanded(
                        child: Text(
                          data.value,
                          style: TextStyle(
                            fontSize: valueSize,
                            fontWeight: FontWeight.bold,
                            color: data.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          softWrap: false,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: spacing),
                  Text(
                    data.title,
                    style: TextStyle(color: Colors.grey[700], fontSize: labelSize),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    softWrap: false,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    final crossAxisCount = MediaQuery.of(context).size.width > 700 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: crossAxisCount * 2,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.6,
      ),
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
        );
      },
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acceso Rápido',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              context,
              'Agregar Producto',
              Icons.add_box,
              Colors.blue,
              () => widget.onNavigateToAddProduct(context),
            ),
            _buildQuickActionCard(
              context,
              'Gestionar Clientes',
              Icons.people,
              Colors.orange,
              () => widget.onNavigateToClients(context),
            ),
            _buildQuickActionCard(
              context,
              'Ver Inventario',
              Icons.inventory_2,
              Colors.purple,
              () => widget.onNavigateToHome(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 6),
              Flexible(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSystemInfo(BuildContext context) {
    final now = DateTime.now();
    final lastUpdate = now.subtract(const Duration(minutes: 2));
    final m = _metrics;
    final dbText = m != null
        ? 'Base de datos: ${m.totalClients} clientes, ${m.totalProducts} productos'
        : 'Base de datos: cargando...';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Estado del Sistema',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sistema funcionando correctamente',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.update, color: Colors.blue[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Última actualización: ${_formatTime(lastUpdate)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.storage, color: Colors.orange[700], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dbText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else {
      return 'Hace ${difference.inDays} días';
    }
  }

}

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _MetricCardData(this.title, this.value, this.icon, this.color, this.onTap);
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Acciones Rápidas',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de acciones
          _buildActionList(context),
        ],
      ),
    );
  }

  Widget _buildActionList(BuildContext context) {
    final actions = [
      {
        'title': 'Escanear Cliente',
        'subtitle': 'Buscar cliente por código QR',
        'icon': Icons.qr_code_scanner,
        'color': Colors.blue,
        'onTap': () => _scanClient(context),
      },
      {
        'title': 'Nueva Venta',
        'subtitle': 'Crear nueva factura de venta',
        'icon': Icons.shopping_cart,
        'color': Colors.green,
        'onTap': () => _newSale(context),
      },
      {
        'title': 'Agregar Cliente',
        'subtitle': 'Registrar nuevo cliente',
        'icon': Icons.person_add,
        'color': Colors.orange,
        'onTap': () => _addClient(context),
      },
      {
        'title': 'Ver Reportes',
        'subtitle': 'Consultar estadísticas de ventas',
        'icon': Icons.analytics,
        'color': Colors.purple,
        'onTap': () => _viewReports(context),
      },
      {
        'title': 'Configurar Empresa',
        'subtitle': 'Editar información de la empresa',
        'icon': Icons.business,
        'color': Colors.indigo,
        'onTap': () => _configureCompany(context),
      },
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      itemBuilder: (context, index) {
        final action = actions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: action['color'] as Color,
              child: Icon(
                action['icon'] as IconData,
                color: Colors.white,
              ),
            ),
            title: Text(action['title'] as String),
            subtitle: Text(action['subtitle'] as String),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: action['onTap'] as VoidCallback,
          ),
        );
      },
    );
  }

  void _scanClient(BuildContext context) async {
    try {
      final String? scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      if (scannedCode != null && scannedCode.isNotEmpty) {
        // Navegar a la información del cliente escaneado
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ClientInfoScreen(clientCode: scannedCode),
          ),
        );
      }
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al escanear: $e'),
          backgroundColor: Colors.red,
        ),
    );
    }
  }

  void _newSale(BuildContext context) {
    // Mostrar opciones para nueva venta
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_cart, color: Colors.green),
                  const SizedBox(width: 8),
                  Text(
                    'Nueva Venta',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.qr_code_scanner, color: Colors.white),
                ),
                title: const Text('Escanear Cliente'),
                subtitle: const Text('Buscar cliente por código QR para venta directa'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pop();
                  _scanClient(context);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.orange,
                  child: Icon(Icons.inventory_2, color: Colors.white),
                ),
                title: const Text('Venta General'),
                subtitle: const Text('Acceder al inventario para venta general'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const InventoryDashboardScreen(),
      ),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _addClient(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SellerClientsScreen(),
      ),
    );
  }

  void _viewReports(BuildContext context) {
    // Mostrar pantalla de reportes básicos
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, controller) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.analytics, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      'Reportes y Estadísticas',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    controller: controller,
                    children: [
                      _buildReportCard(
                        context,
                        'Resumen de Inventario',
                        'Ver estadísticas de productos y stock',
                        Icons.inventory_2,
                        Colors.blue,
                        () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const InventoryDashboardScreen(),
                            ),
                          );
                        },
                      ),
                      _buildReportCard(
                        context,
                        'Clientes de Crédito',
                        'Ver clientes con saldo pendiente',
                        Icons.account_balance_wallet,
                        Colors.orange,
                        () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SellerClientsScreen(showCreditOnly: true),
                            ),
                          );
                        },
                      ),
                      _buildReportCard(
                        context,
                        'Todos los Clientes',
                        'Gestionar todos los clientes registrados',
                        Icons.people,
                        Colors.green,
                        () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SellerClientsScreen(),
                            ),
                          );
                        },
                      ),
                      _buildReportCard(
                        context,
                        'Configuración',
                        'Configurar información de la empresa',
                        Icons.business,
                        Colors.indigo,
                        () {
                          Navigator.of(context).pop();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CompanyScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  void _configureCompany(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CompanyScreen(),
      ),
    );
  }
}

class _RecentActivity extends StatefulWidget {
  const _RecentActivity();

  @override
  State<_RecentActivity> createState() => _RecentActivityState();
}

class _RecentActivityState extends State<_RecentActivity> {
  final ClientService _clientService = ClientService();
  final InventoryService _inventoryService = InventoryService();
  
  List<Client> _clients = [];
  List<Product> _products = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clients = await _clientService.getClients();
      final products = await _inventoryService.getProducts();
      
      setState(() {
        _clients = clients;
        _products = products;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de Datos',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de actividades
          _buildActivityList(context),
        ],
      ),
    );
  }

  Widget _buildActivityList(BuildContext context) {
    if (_clients.isEmpty && _products.isEmpty) {
      return _buildEmptyState(context);
    }

    final activities = <Map<String, dynamic>>[];

    // Agregar clientes recientes (últimos 5)
    final recentClients = _clients.take(5).toList();
    for (final client in recentClients) {
      activities.add({
        'title': 'Cliente registrado',
        'subtitle': '${client.name} - Código: ${client.code}',
        'time': 'Reciente',
        'icon': Icons.person_add,
        'color': Colors.orange,
      });
    }

    // Agregar productos con stock bajo
    final lowStockProducts = _products.where((p) => p.quantity < 10).take(3).toList();
    for (final product in lowStockProducts) {
      activities.add({
        'title': 'Stock bajo',
        'subtitle': '${product.name} - Solo ${product.quantity} unidades',
        'time': 'Revisar',
        'icon': Icons.warning,
        'color': Colors.amber,
      });
    }

    // Agregar productos sin stock
    final outOfStockProducts = _products.where((p) => p.quantity == 0).take(2).toList();
    for (final product in outOfStockProducts) {
      activities.add({
        'title': 'Sin stock',
        'subtitle': '${product.name} - Agotado',
        'time': 'Urgente',
        'icon': Icons.error,
        'color': Colors.red,
      });
    }

    if (activities.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: activity['color'] as Color,
              child: Icon(
                activity['icon'] as IconData,
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(activity['title'] as String),
            subtitle: Text(activity['subtitle'] as String),
            trailing: Text(
              activity['time'] as String,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay datos disponibles',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Agrega clientes y productos para ver el resumen aquí',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
