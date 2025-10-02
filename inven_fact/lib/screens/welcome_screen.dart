import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'barcode_scanner_screen.dart';
import 'client_info_screen.dart';
import 'seller_dashboard_screen.dart';
import 'seller_login_screen.dart';
import 'dev_tools_screen.dart';
import '../services/client_context_service.dart';
import '../services/client_service.dart';
import '../services/auth_service.dart';
import '../models/client.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final TextEditingController _clientCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final ClientContextService _clientContext = ClientContextService();
  final ClientService _clientService = ClientService();
  final AuthService _authService = AuthService();
  int _continueTapCount = 0;
  bool _devVisible = true;
  bool _sellerVisible = true;
  bool _isCheckingAutoLogin = false;
  static const String _devButtonHiddenKey = 'dev_button_hidden';
  static const String _sellerButtonHiddenKey = 'seller_button_hidden';

  @override
  void initState() {
    super.initState();
    // Listener para detectar cambios en el campo de texto
    _clientCodeController.addListener(_onTextChanged);
    // Cargar estado de autenticación
    _checkAutoLogin();
    _loadDevButtonVisibility();
  }

  Future<void> _loadDevButtonVisibility() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hidden = prefs.getBool(_devButtonHiddenKey) ?? false;
      if (!mounted) return;
      setState(() {
        _devVisible = !hidden;
        _sellerVisible = !(prefs.getBool(_sellerButtonHiddenKey) ?? false);
      });
    } catch (_) {}
  }

  Future<void> _checkAutoLogin() async {
    setState(() {
      _isCheckingAutoLogin = true;
    });
    try {
      await _authService.loadAuthState();
      final remember = await _authService.getRememberMe();
      if (remember && _authService.isAuthenticated()) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
        );
        return;
      }
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isCheckingAutoLogin = false;
      });
    }
  }

  void _onTextChanged() {
    final text = _clientCodeController.text.trim();
    // Si el código tiene exactamente 6 dígitos, avanzar automáticamente
    if (text.length == 6 && RegExp(r'^\d{6}$').hasMatch(text)) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_formKey.currentState != null && _formKey.currentState!.validate()) {
          _continueToApp();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 500,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título grande y eslogan
                  Column(
                    children: [
                      Text(
                        'INVE FACT',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: Colors.blue[800],
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sistema de Inventario Completo',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Formulario de acceso de cliente
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _clientCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Código de Cliente',
                                hintText: 'Ingresa 6 dígitos',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.qr_code_2),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(6),
                              ],
                              validator: (value) {
                                final v = (value ?? '').trim();
                                if (!RegExp(r'^\d{6}$').hasMatch(v)) {
                                  return 'Ingresa un código válido de 6 dígitos';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  if (_formKey.currentState?.validate() == true) {
                                    _continueToApp();
                                  } else {
                                    // Contador oculto para reactivar botón de desarrollador
                                    _continueTapCount++;
                                    if (_continueTapCount >= 5) {
                                      setState(() {
                                        _devVisible = true;
                                        _continueTapCount = 0;
                                      });
                                      SharedPreferences.getInstance().then((prefs) {
                                        prefs.setBool(_devButtonHiddenKey, false);
                                      });
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('🔓 Botón de desarrollador activado')),
                                      );
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Por favor ingresa un código de 6 dígitos'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.login),
                                label: const Text('Continuar'),
                              ),
                            ),
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _scanClientCode,
                              icon: const Icon(Icons.qr_code_scanner),
                              label: const Text('Escanear código'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      // Botones flotantes: Modo Vendedor y (si debug) Desarrollador
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (kDebugMode && _devVisible) ...[
            FloatingActionButton(
              heroTag: 'dev_fab',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const DevToolsScreen(),
                  ),
                );
                if (mounted) {
                  _loadDevButtonVisibility();
                }
              },
              backgroundColor: Colors.orange[600],
              tooltip: 'Herramientas de Desarrollo',
              child: const Icon(Icons.build, color: Colors.white),
            ),
            const SizedBox(width: 12),
          ],
          if (_sellerVisible)
          FloatingActionButton(
            heroTag: 'seller_fab',
            onPressed: _enterSellerMode,
            backgroundColor: Colors.blue[700],
            tooltip: 'Modo Vendedor',
            child: const Icon(Icons.store, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _enterSellerMode() {
    // Siempre ir al login para mayor seguridad
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SellerLoginScreen(),
      ),
    );
  }

  void _showClientMode() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          contentPadding: const EdgeInsets.all(16),
          title: const Text('Acceso de Cliente'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360, maxHeight: 240),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Introduce o escanea tu código para ver y comprar productos:',
                    textAlign: TextAlign.center,
                    softWrap: true,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _clientCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Código de cliente (6 dígitos)',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor introduce un código de cliente';
                      }
                      if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
                        return 'El código debe tener exactamente 6 dígitos';
                      }
                      return null;
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
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
            ElevatedButton.icon(
              onPressed: _scanClientCode,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Escanear'),
            ),
            ElevatedButton(
              onPressed: () {
                final clientCode = _clientCodeController.text.trim();
                if (clientCode.isNotEmpty && clientCode.length == 6) {
                  Navigator.of(context).pop();
                  _continueToApp();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Por favor ingresa un código de 6 dígitos'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        );
      },
    );
  }

  void _continueToApp() async {
    final clientCode = _clientCodeController.text.trim();
    try {
      // Primero buscar en la base de datos SQLite (clientes registrados por vendedor)
      Client? client = await _clientService.getClientByCode(clientCode);
      
      if (client != null) {
        // Cliente encontrado en la base de datos del vendedor
        await _clientContext.setCurrentClient(clientCode);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bienvenido, ${client.name}'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
            ),
          );

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ClientInfoScreen(clientCode: clientCode),
            ),
          );
        }
      } else {
        // Cliente no encontrado en la base de datos SQLite, mostrar error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cliente con código "$clientCode" no encontrado. Contacta al vendedor para registrarte.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al inicializar cliente: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scanClientCode() async {
    // Abrir escáner de código de barras
    try {
      final String? scannedCode = await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (context) => const BarcodeScannerScreen(),
        ),
      );
      
      if (scannedCode != null && scannedCode.isNotEmpty) {
        // Introducir el código escaneado en el campo de texto
        _clientCodeController.text = scannedCode;
        
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Código escaneado: $scannedCode'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        
        // Si tiene exactamente 6 dígitos, avanzar automáticamente
        if (scannedCode.length == 6 && RegExp(r'^\d{6}$').hasMatch(scannedCode)) {
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (_formKey.currentState != null && _formKey.currentState!.validate()) {
              _continueToApp();
            }
          });
        }
      }
    } catch (e) {
      // Manejar errores del escáner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al abrir el escáner: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _clientCodeController.dispose();
    super.dispose();
  }
}