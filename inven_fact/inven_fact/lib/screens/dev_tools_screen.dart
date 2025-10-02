import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/reset_first_login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/test_id_change.dart';
import '../utils/debug_login.dart';
import '../utils/debug_clients.dart';
import '../utils/test_product_saving.dart';
import '../utils/test_product_saving_fix.dart';
import '../utils/populate_default_data.dart';
import '../utils/database_diagnostic.dart';
import '../utils/reset_app.dart';
import '../utils/debug_vendedor001.dart';
import '../utils/setup_initial_config.dart';
import '../utils/debug_database_connection.dart';
import '../utils/fix_database_connection.dart';
import '../services/client_context_service.dart';

class DevToolsScreen extends StatefulWidget {
  const DevToolsScreen({super.key});

  @override
  State<DevToolsScreen> createState() => _DevToolsScreenState();
}

class _DevToolsScreenState extends State<DevToolsScreen> {
  bool _isLoading = false;
  bool _devButtonHidden = false;
  static const String _devButtonHiddenKey = 'dev_button_hidden';
  static const String _sellerButtonHiddenKey = 'seller_button_hidden';

  Future<void> _resetFirstLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ResetFirstLogin.resetFirstLoginState();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Estado de primer login reseteado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testIdChange() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await TestIdChange.testIdChange();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🧪 Prueba de cambio de ID ejecutada - Ver consola'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Eliminado build duplicado (se mantiene el principal al final del archivo)

  Future<void> _debugLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugLogin.debugLoginIssue();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Debug de login ejecutado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixRandySeller() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugLogin.fixRandySeller();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 Vendedor RANDY arreglado - Ver consola'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugAllClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugClients.debugAllClients();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Debug de clientes ejecutado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugClient654321() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugClients.debugClientByCode('654321');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Debug cliente 654321 - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fixAccountTypes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugClients.fixAccountTypes();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔧 Tipos de cuenta corregidos - Ver consola'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSellersStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ResetFirstLogin.showSellersStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📊 Estado mostrado en consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAllSellers() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirmar Reset Completo'),
        content: const Text(
          'Esto eliminará TODOS los vendedores y datos de autenticación.\n\n'
          '¿Estás seguro de que quieres continuar?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Resetear Todo'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await ResetFirstLogin.resetAllSellers();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Todo reseteado completamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _factoryReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Restablecer de fábrica'),
        content: const Text(
          'Esto borrará todos los datos y restaurará el vendedor por defecto:\n\n'
          'ID: VENDEDOR001\nContraseña: 123456\n\n'
          '¿Deseas continuar?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Restablecer')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await ResetApp.resetCompleteApp();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Restablecido de fábrica. Reinicia la app.'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hideDeveloperButton() async {
    setState(() {
      _devButtonHidden = true;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_devButtonHiddenKey, true);
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🔒 Botón de desarrollador oculto. Reactívalo tocando "Continuar" 5 veces en bienvenida.'), backgroundColor: Colors.blue),
      );
    }
  }

  Future<void> _hideSellerButton() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sellerButtonHiddenKey, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('🔒 Botón de vendedor oculto.')), 
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al ocultar: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _populateDefaultData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await PopulateDefaultData.populateAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos por defecto poblados exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _clearAllData() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('⚠️ CONFIRMAR LIMPIEZA TOTAL'),
          content: const Text(
            'Esta acción eliminará TODOS los datos:\n\n'
            '• Todos los vendedores\n'
            '• Todos los clientes\n'
            '• Todos los productos\n'
            '• Todas las configuraciones\n\n'
            'Solo quedará VENDEDOR001 con contraseña 123456\n\n'
            '¿Estás seguro de continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('ELIMINAR TODO'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await PopulateDefaultData.clearAllData();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Datos limpiados. Reinicia la app para aplicar cambios'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Limpiar solo SharedPreferences (función segura)
  Future<void> _clearSharedPreferencesOnly() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔄 CONFIRMAR LIMPIEZA SEGURA'),
          content: const Text(
            'Esta acción limpiará solo SharedPreferences:\n\n'
            '• Configuraciones de la app\n'
            '• Datos de sesión\n'
            '• Preferencias del usuario\n\n'
            'NO tocará la base de datos SQLite\n'
            'Se configurará VENDEDOR001 como vendedor por defecto\n\n'
            '¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('LIMPIAR'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await PopulateDefaultData.clearSharedPreferencesOnly();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ SharedPreferences limpiado. Reinicia la app'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Diagnosticar problemas de base de datos
  Future<void> _diagnoseDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseDiagnostic.diagnoseDatabase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Diagnóstico completado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Recrear base de datos desde cero
  Future<void> _recreateDatabase() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔧 RECREAR BASE DE DATOS'),
          content: const Text(
            'Esta acción eliminará la base de datos actual y creará una nueva:\n\n'
            '• Se eliminará toda la información\n'
            '• Se creará VENDEDOR001 automáticamente\n'
            '• Se reiniciará la aplicación\n\n'
            '¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('RECREAR'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await DatabaseDiagnostic.recreateDatabase();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Base de datos recreada. Reinicia la app'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al recrear: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Reset completo de la aplicación
  Future<void> _resetCompleteApp() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔧 RESET COMPLETO DE LA APLICACIÓN'),
          content: const Text(
            'Esta acción hará un reset completo:\n\n'
            '• Eliminará la base de datos corrupta\n'
            '• Creará una nueva base de datos\n'
            '• Configurará VENDEDOR001 automáticamente\n'
            '• Limpiará todas las configuraciones\n\n'
            '¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('RESET COMPLETO'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ResetApp.resetCompleteApp();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Reset completo exitoso. Reinicia la app'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en reset: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verificar estado de la aplicación
  Future<void> _checkAppStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await ResetApp.checkAppStatus();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Estado verificado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al verificar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Debug específico para VENDEDOR001
  Future<void> _debugVendedor001() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugVendedor001.debugVendedor001();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Debug VENDEDOR001 completado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en debug: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Crear VENDEDOR001 si no existe
  Future<void> _createVendedor001() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugVendedor001.createVendedor001();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ VENDEDOR001 creado/verificado - Ver consola'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear VENDEDOR001: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Configurar VENDEDOR001 en SharedPreferences
  Future<void> _setupVendedor001() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SetupInitialConfig.setupVendedor001();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ VENDEDOR001 configurado en SharedPreferences'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al configurar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verificar configuración actual
  Future<void> _checkCurrentConfig() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await SetupInitialConfig.checkCurrentConfig();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Configuración verificada - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al verificar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Probar guardado de productos (versión corregida)
  Future<void> _testProductSavingFix() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await TestProductSavingFix.testProductSaving();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Prueba de guardado exitosa - Ver consola'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en prueba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Diagnóstico completo de base de datos
  Future<void> _runDatabaseDiagnostic() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DebugDatabaseConnection.runFullDiagnostic();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🔍 Diagnóstico completo ejecutado - Ver consola'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en diagnóstico: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Prueba rápida de conexión
  Future<void> _quickConnectionTest() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isConnected = await DebugDatabaseConnection.quickConnectionTest();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isConnected ? '✅ Conexión exitosa' : '❌ Error de conexión'),
            backgroundColor: isConnected ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en prueba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Reparar conexión a la base de datos
  Future<void> _fixDatabaseConnection() async {
    // Mostrar diálogo de confirmación
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('🔧 REPARAR BASE DE DATOS'),
          content: const Text(
            'Esta acción reparará la conexión a la base de datos:\n\n'
            '• Eliminará la base de datos corrupta\n'
            '• Creará una nueva base de datos\n'
            '• Configurará VENDEDOR001 automáticamente\n'
            '• Limpiará SharedPreferences\n\n'
            '¿Continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.orange),
              child: const Text('REPARAR'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FixDatabaseConnection.fixDatabaseConnection();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Base de datos reparada exitosamente. Reinicia la app'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en reparación: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Verificar estado de la base de datos
  Future<void> _checkDatabaseStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isWorking = await FixDatabaseConnection.isDatabaseWorking();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isWorking ? '✅ Base de datos funcionando correctamente' : '❌ Base de datos tiene problemas'),
            backgroundColor: isWorking ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error verificando estado: $e'),
            backgroundColor: Colors.red,
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
        title: const Text('🛠️ Herramientas de Desarrollo'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.redAccent.withOpacity(0.08),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                        const SizedBox(width: 8),
                        const Text('Acciones rápidas', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _factoryReset,
                      icon: const Icon(Icons.restart_alt),
                      label: const Text('Restablecer de fábrica (VENDEDOR001)'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _hideDeveloperButton,
                      icon: const Icon(Icons.visibility_off),
                      label: const Text('Ocultar botón de desarrollador'),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _hideSellerButton,
                      icon: const Icon(Icons.store_mall_directory),
                      label: const Text('Ocultar botón de vendedor'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Información
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Herramientas de Desarrollo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Usa estas herramientas para resetear el estado de autenticación y probar los cambios.',
                      style: TextStyle(color: Colors.blue[600]),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Botones de acción
            _buildActionButton(
              icon: Icons.refresh,
              title: 'Resetear Primer Login',
              subtitle: 'Permite probar el flujo de cambio de contraseña nuevamente',
              color: Colors.orange,
              onPressed: _resetFirstLogin,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.swap_horiz,
              title: 'Probar Cambio de ID',
              subtitle: 'Prueba automática del cambio de ID de vendedor',
              color: Colors.green,
              onPressed: _testIdChange,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.bug_report,
              title: 'Debug Login',
              subtitle: 'Diagnostica problemas de autenticación',
              color: Colors.orange,
              onPressed: _debugLogin,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.build,
              title: 'Arreglar Vendedor RANDY',
              subtitle: 'Activa y arregla el vendedor RANDY',
              color: Colors.purple,
              onPressed: _fixRandySeller,
            ),
            const SizedBox(height: 16),

            // Nuevos botones para debug de clientes
            _buildActionButton(
              icon: Icons.people,
              title: 'Debug Todos los Clientes',
              subtitle: 'Muestra todos los clientes y sus tipos de cuenta',
              color: Colors.cyan,
              onPressed: _debugAllClients,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.person_search,
              title: 'Debug Cliente 654321',
              subtitle: 'Muestra información específica del cliente 654321',
              color: Colors.teal,
              onPressed: _debugClient654321,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.build_circle,
              title: 'Corregir Tipos de Cuenta',
              subtitle: 'Corrige automáticamente los tipos de cuenta incorrectos',
              color: Colors.amber,
              onPressed: _fixAccountTypes,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.delete_sweep,
              title: 'Borrar Clientes Temporales',
              subtitle: 'Elimina todos los clientes temporales de SharedPreferences',
              color: Colors.red[600]!,
              onPressed: _clearTemporaryClients,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.inventory,
              title: 'Probar Guardado de Productos',
              subtitle: 'Verifica que los productos se guarden correctamente en la base de datos',
              color: Colors.green[600]!,
              onPressed: _testProductSaving,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.bug_report,
              title: '🔧 PROBAR GUARDADO CORREGIDO',
              subtitle: 'Prueba la versión corregida del guardado de productos',
              color: Colors.green[700]!,
              onPressed: _testProductSavingFix,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.data_object,
              title: 'Poblar Datos por Defecto',
              subtitle: 'Crea vendedores, clientes y productos de ejemplo para desarrollo',
              color: Colors.purple,
              onPressed: _populateDefaultData,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.delete_forever,
              title: '🧹 LIMPIAR TODO Y DEJAR SOLO VENDEDOR001',
              subtitle: 'Elimina TODOS los datos y deja solo VENDEDOR001 con contraseña 123456',
              color: Colors.red[800]!,
              onPressed: _clearAllData,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.settings_backup_restore,
              title: '🔄 LIMPIEZA SEGURA (Solo SharedPreferences)',
              subtitle: 'Limpia solo SharedPreferences sin tocar la base de datos (más seguro)',
              color: Colors.orange[700]!,
              onPressed: _clearSharedPreferencesOnly,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.bug_report,
              title: '🔍 DIAGNOSTICAR BASE DE DATOS',
              subtitle: 'Verifica el estado de la base de datos y muestra información detallada',
              color: Colors.blue[700]!,
              onPressed: _diagnoseDatabase,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.refresh,
              title: '🔧 RECREAR BASE DE DATOS',
              subtitle: 'Elimina y recrea la base de datos desde cero (SOLUCIONA ERRORES)',
              color: Colors.red[700]!,
              onPressed: _recreateDatabase,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.restart_alt,
              title: '🚀 RESET COMPLETO DE LA APLICACIÓN',
              subtitle: 'Elimina base de datos corrupta, crea nueva y configura VENDEDOR001',
              color: Colors.purple[800]!,
              onPressed: _resetCompleteApp,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.info,
              title: '📊 VERIFICAR ESTADO DE LA APP',
              subtitle: 'Muestra el estado actual de SharedPreferences y base de datos',
              color: Colors.cyan[700]!,
              onPressed: _checkAppStatus,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.person_search,
              title: '🔍 DEBUG VENDEDOR001',
              subtitle: 'Verifica específicamente el estado de VENDEDOR001 y su autenticación',
              color: Colors.indigo[700]!,
              onPressed: _debugVendedor001,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.person_add,
              title: '➕ CREAR VENDEDOR001',
              subtitle: 'Crea VENDEDOR001 si no existe en la base de datos',
              color: Colors.green[700]!,
              onPressed: _createVendedor001,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.settings,
              title: '⚙️ CONFIGURAR VENDEDOR001',
              subtitle: 'Configura VENDEDOR001 en SharedPreferences (SOLUCIONA LOGIN)',
              color: Colors.orange[700]!,
              onPressed: _setupVendedor001,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.check_circle,
              title: '✅ VERIFICAR CONFIGURACIÓN',
              subtitle: 'Verifica la configuración actual de SharedPreferences',
              color: Colors.teal[700]!,
              onPressed: _checkCurrentConfig,
            ),
            const SizedBox(height: 16),

            // Nuevos botones para reparar base de datos
            _buildActionButton(
              icon: Icons.build,
              title: '🔧 REPARAR BASE DE DATOS',
              subtitle: 'SOLUCIONA el error de conexión SQLite (RECOMENDADO)',
              color: Colors.red[700]!,
              onPressed: _fixDatabaseConnection,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.health_and_safety,
              title: '🏥 VERIFICAR ESTADO DE BD',
              subtitle: 'Verifica si la base de datos está funcionando correctamente',
              color: Colors.blue[600]!,
              onPressed: _checkDatabaseStatus,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.speed,
              title: '⚡ PRUEBA RÁPIDA DE CONEXIÓN',
              subtitle: 'Prueba rápida para verificar la conectividad',
              color: Colors.green[600]!,
              onPressed: _quickConnectionTest,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.bug_report,
              title: '🔍 DIAGNÓSTICO COMPLETO',
              subtitle: 'Ejecuta un diagnóstico detallado de la base de datos',
              color: Colors.purple[600]!,
              onPressed: _runDatabaseDiagnostic,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.info_outline,
              title: 'Ver Estado de Vendedores',
              subtitle: 'Muestra el estado actual en la consola',
              color: Colors.blue,
              onPressed: _showSellersStatus,
            ),
            const SizedBox(height: 16),

            _buildActionButton(
              icon: Icons.delete_forever,
              title: 'Resetear Todo',
              subtitle: 'Elimina todos los vendedores y datos (PELIGROSO)',
              color: Colors.red,
              onPressed: _resetAllSellers,
            ),
            const SizedBox(height: 24),

            // Instrucciones
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 Instrucciones:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '1. Usa "Resetear Primer Login" para probar el cambio de contraseña\n'
                      '2. Ve a "Modo Vendedor" y haz login con VENDEDOR001 / 123456\n'
                      '3. Ahora aparecerá la pantalla de configuración inicial\n'
                      '4. Prueba cambiar la contraseña, nombre e ID opcionalmente\n'
                      '5. Usa "Probar Cambio de ID" para verificar que funciona',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                  ],
                ),
              ),
            ),

            if (_isLoading) ...[
              const SizedBox(height: 24),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: _isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (_isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _clearTemporaryClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final clientContext = ClientContextService();
      final deletedCount = await clientContext.clearAllTemporaryClients();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $deletedCount clientes temporales eliminados'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testProductSaving() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await testProductSaving();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Prueba de productos completada - Revisa la consola'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error en prueba: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
