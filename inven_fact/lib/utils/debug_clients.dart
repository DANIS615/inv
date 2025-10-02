import 'package:inven_fact/services/client_service.dart';
import 'package:inven_fact/models/client.dart';

class DebugClients {
  static final ClientService _clientService = ClientService();

  /// Debug: Mostrar todos los clientes y sus tipos de cuenta
  static Future<void> debugAllClients() async {
    print('=== DEBUG: Todos los Clientes ===');
    
    try {
      final clients = await _clientService.getClients();
      
      if (clients.isEmpty) {
        print('No hay clientes en la base de datos.');
        return;
      }
      
      for (var client in clients) {
        print('ID: ${client.id}');
        print('Nombre: ${client.name}');
        print('Código: ${client.code}');
        print('Tipo de Cuenta: ${client.accountType}');
        print('Tipo de Cuenta (String): ${client.accountType.name}');
        print('Saldo Pendiente: ${client.pendingBalance}');
        print('Activo: ${client.isActive}');
        print('---');
      }
    } catch (e) {
      print('Error al obtener clientes: $e');
    }
  }

  /// Debug: Mostrar un cliente específico por código
  static Future<void> debugClientByCode(String code) async {
    print('=== DEBUG: Cliente $code ===');
    
    try {
      final client = await _clientService.getClientByCode(code);
      
      if (client == null) {
        print('Cliente $code no encontrado.');
        return;
      }
      
      print('ID: ${client.id}');
      print('Nombre: ${client.name}');
      print('Código: ${client.code}');
      print('Tipo de Cuenta: ${client.accountType}');
      print('Tipo de Cuenta (String): ${client.accountType.name}');
      print('Saldo Pendiente: ${client.pendingBalance}');
      print('Activo: ${client.isActive}');
    } catch (e) {
      print('Error al obtener cliente $code: $e');
    }
  }

  /// Debug: Mostrar datos raw de la base de datos
  static Future<void> debugRawData() async {
    print('=== DEBUG: Datos Raw de la Base de Datos ===');
    
    try {
      final db = await _clientService.database;
      final maps = await db.query('clients_general');
      
      if (maps.isEmpty) {
        print('No hay datos en la tabla clients_general.');
        return;
      }
      
      for (var map in maps) {
        print('Datos raw:');
        map.forEach((key, value) {
          print('  $key: $value (${value.runtimeType})');
        });
        print('---');
      }
    } catch (e) {
      print('Error al obtener datos raw: $e');
    }
  }

  /// Corregir tipos de cuenta incorrectos
  static Future<void> fixAccountTypes() async {
    print('=== CORRIGIENDO TIPOS DE CUENTA ===');
    
    try {
      final clients = await _clientService.getClients();
      int fixed = 0;
      
      for (var client in clients) {
        // Si el cliente tiene saldo pendiente > 0, debería ser crédito
        if (client.pendingBalance > 0 && client.accountType == AccountType.contado) {
          print('Corrigiendo ${client.name} (${client.code}): Contado -> Crédito');
          
          final updatedClient = client.copyWith(accountType: AccountType.credito);
          await _clientService.updateClient(updatedClient);
          fixed++;
        }
      }
      
      print('Se corrigieron $fixed clientes.');
    } catch (e) {
      print('Error al corregir tipos de cuenta: $e');
    }
  }
}
