import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'seller_dashboard_screen.dart';
import 'company_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _newNameController = TextEditingController();
  final _newIdController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _changeName = false;
  bool _changeId = false;

  @override
  void initState() {
    super.initState();
    // Cargar el nombre e ID actual del vendedor
    _newNameController.text = _authService.sellerName ?? '';
    _newIdController.text = _authService.sellerId ?? '';
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newNameController.dispose();
    _newIdController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Cambiar contraseña
      final passwordSuccess = await _authService.changePassword(_newPasswordController.text.trim());
      
      // Cambiar nombre si está habilitado
      bool nameSuccess = true;
      if (_changeName && _newNameController.text.trim().isNotEmpty) {
        nameSuccess = await _authService.changeSellerName(_newNameController.text.trim());
      }
      
      // Cambiar ID si está habilitado
      bool idSuccess = true;
      if (_changeId && _newIdController.text.trim().isNotEmpty) {
        idSuccess = await _authService.changeSellerId(_newIdController.text.trim());
      }
      
      if (passwordSuccess && nameSuccess && idSuccess) {
        if (mounted) {
          String message = 'Contraseña cambiada exitosamente';
          if (_changeName && _newNameController.text.trim().isNotEmpty) {
            message += ' y nombre actualizado';
            // Actualizar el estado del AuthService para reflejar el nuevo nombre
            _authService.updateCurrentSellerName(_newNameController.text.trim());
          }
          if (_changeId && _newIdController.text.trim().isNotEmpty) {
            message += ' y ID actualizado';
            // Actualizar el estado del AuthService para reflejar el nuevo ID
            _authService.updateCurrentSellerId(_newIdController.text.trim());
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navegar a configuración de empresa en primer login
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const CompanyScreen(),
            ),
          );
        }
      } else {
        if (mounted) {
          String errorMessage = 'Error al actualizar la información.';
          if (!idSuccess) {
            errorMessage = 'El ID de vendedor ya está en uso. Elige otro ID.';
          } else if (!nameSuccess) {
            errorMessage = 'Error al actualizar el nombre.';
          } else if (!passwordSuccess) {
            errorMessage = 'Error al cambiar la contraseña.';
          }
          _showErrorDialog(errorMessage);
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
        title: const Text('Error'),
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
        title: const Text('Cambiar Contraseña'),
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
                  // Icono
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_reset,
                      size: 64,
                      color: Colors.orange[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Título
                  Text(
                    'Configuración Inicial',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Configura tu contraseña y opcionalmente tu nombre de usuario',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Formulario
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
                           // Switch para cambiar ID
                           Card(
                             color: Colors.green[50],
                             child: SwitchListTile(
                               title: const Text('Cambiar ID de Vendedor'),
                               subtitle: const Text('Opcional - Cambia VENDEDOR001 por tu ID personalizado'),
                               value: _changeId,
                               onChanged: (value) {
                                 setState(() {
                                   _changeId = value;
                                 });
                               },
                               activeColor: Colors.green[600],
                             ),
                           ),
                           const SizedBox(height: 16),

                           // Campo de ID (solo si está habilitado)
                           if (_changeId) ...[
                             TextFormField(
                               controller: _newIdController,
                               decoration: const InputDecoration(
                                 labelText: 'Nuevo ID de Vendedor *',
                                 hintText: 'Ingresa tu nuevo ID (ej: VENDEDOR002)',
                                 prefixIcon: Icon(Icons.badge),
                                 border: OutlineInputBorder(),
                               ),
                               textCapitalization: TextCapitalization.characters,
                               validator: (value) {
                                 if (_changeId && (value == null || value.trim().isEmpty)) {
                                   return 'El ID de vendedor es requerido';
                                 }
                                 if (_changeId && value != null && value.trim().length < 3) {
                                   return 'El ID debe tener al menos 3 caracteres';
                                 }
                                 return null;
                               },
                             ),
                             const SizedBox(height: 16),
                           ],

                           // Switch para cambiar nombre
                           Card(
                             color: Colors.blue[50],
                             child: SwitchListTile(
                               title: const Text('Cambiar Nombre de Usuario'),
                               subtitle: const Text('Opcional - Mantén el nombre actual si no quieres cambiarlo'),
                               value: _changeName,
                               onChanged: (value) {
                                 setState(() {
                                   _changeName = value;
                                 });
                               },
                               activeColor: Colors.blue[600],
                             ),
                           ),
                          const SizedBox(height: 16),

                          // Campo de nombre (solo si está habilitado)
                          if (_changeName) ...[
                            TextFormField(
                              controller: _newNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nuevo Nombre de Usuario *',
                                hintText: 'Ingresa tu nuevo nombre',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                              validator: (value) {
                                if (_changeName && (value == null || value.trim().isEmpty)) {
                                  return 'El nombre de usuario es requerido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Nueva Contraseña
                          TextFormField(
                            controller: _newPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Nueva Contraseña *',
                              hintText: 'Ingresa tu nueva contraseña',
                              prefixIcon: const Icon(Icons.lock),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureNewPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureNewPassword = !_obscureNewPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureNewPassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La nueva contraseña es requerida';
                              }
                              if (value.length < 6) {
                                return 'La contraseña debe tener al menos 6 caracteres';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Confirmar Contraseña
                          TextFormField(
                            controller: _confirmPasswordController,
                            decoration: InputDecoration(
                              labelText: 'Confirmar Nueva Contraseña *',
                              hintText: 'Confirma tu nueva contraseña',
                              prefixIcon: const Icon(Icons.lock_outline),
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            obscureText: _obscureConfirmPassword,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'La confirmación de contraseña es requerida';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Botón de Cambiar Contraseña
                          ElevatedButton(
                            onPressed: _isLoading ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[600],
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
                                 : Text(
                                     (_changeName || _changeId) ? 'Actualizar Información' : 'Cambiar Contraseña',
                                     style: const TextStyle(
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

                  // Información de seguridad
                  Card(
                    color: Colors.blue[50],
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.security, color: Colors.blue[700], size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Requisitos de Seguridad:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '• Mínimo 6 caracteres\n• Usa una combinación de letras y números\n• Evita contraseñas obvias o fáciles de adivinar',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
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
