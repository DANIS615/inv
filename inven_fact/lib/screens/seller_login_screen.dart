import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'seller_dashboard_screen.dart';
import 'change_password_screen.dart';

class SellerLoginScreen extends StatefulWidget {
  const SellerLoginScreen({super.key});

  @override
  State<SellerLoginScreen> createState() => _SellerLoginScreenState();
}

class _SellerLoginScreenState extends State<SellerLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _sellerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _showDefaultCreds = true;
  bool _rememberMe = false;

  // Credenciales por defecto (en producción esto debería venir de una base de datos)
  static const String _defaultSellerId = 'VENDEDOR001';
  static const String _defaultPassword = '123456';

  @override
  void initState() {
    super.initState();
    _prefillLastSellerId();
    _maybeAutoEnter();
  }
  Future<void> _maybeAutoEnter() async {
    await _authService.loadAuthState();
    final remember = await _authService.getRememberMe();
    if (remember && _authService.isAuthenticated() && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const SellerDashboardScreen()),
      );
    }
  }


  Future<void> _prefillLastSellerId() async {
    final lastId = await _authService.getLastSellerId();
    final showDefault = await _authService.getShowDefaultCreds();
    final remember = await _authService.getRememberMe();
    if (!mounted) return;
    setState(() {
      if (lastId != null && lastId.isNotEmpty) {
        _sellerIdController.text = lastId;
      } else {
        _sellerIdController.text = _defaultSellerId;
      }
      _showDefaultCreds = showDefault;
      _rememberMe = remember;
    });
  }

  @override
  void dispose() {
    _sellerIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sellerId = _sellerIdController.text.trim();
      final password = _passwordController.text.trim();

      // Validar credenciales usando el servicio
      final success = await _authService.loginSeller(sellerId, password);
        
      if (success) {
        if (mounted) {
          try {
            await _authService.setRememberMe(_rememberMe);
          } catch (_) {
            // Ignorar si el VM no ha reconocido el método aún (hot reload)
          }
          // Verificar si es primer login
          if (_authService.isFirstLogin) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const ChangePasswordScreen(),
              ),
            );
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const SellerDashboardScreen(),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          _showErrorDialog('Credenciales incorrectas. Verifica tu ID y contraseña.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog('Error inesperado: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error de Autenticación'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Vendedor'),
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
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            tooltip: 'Volver al Inicio',
          ),
        ],
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 500,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Logo/Icono
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.store,
                      size: 64,
                      color: Theme.of(context).primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  Text(
                    'Iniciar Sesión - Vendedor',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accede a tu panel de administración',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Formulario de login
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ID del Vendedor
                          TextFormField(
                            controller: _sellerIdController,
                            decoration: const InputDecoration(
                              labelText: 'ID del Vendedor *',
                              hintText: 'Ej: VENDEDOR001',
                              prefixIcon: Icon(Icons.badge),
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.characters,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'El ID del vendedor es requerido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Contraseña
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Contraseña *',
                              hintText: 'Ingresa tu contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _isLoading ? null : _login(),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La contraseña es requerida';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Checkbox(
                                value: _rememberMe,
                                onChanged: (v) {
                                  setState(() {
                                    _rememberMe = v ?? false;
                                  });
                                },
                              ),
                              const Text('Mantener sesión iniciada'),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Botón de Login
                          ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Iniciar Sesión',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Información de credenciales por defecto (solo si aplica)
                  if (_showDefaultCreds)
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Credenciales por defecto:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'ID: VENDEDOR001\nContraseña: 123456',
                              style: TextStyle(
                                color: Colors.blue,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Nota: En el primer login podrás cambiar tu ID y contraseña',
                              style: TextStyle(
                                color: Colors.orange[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),

                  // Botón para volver
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Volver al inicio'),
                  ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}