import 'package:shared_preferences/shared_preferences.dart';

class ClientContextService {
  static const String _currentClientKey = 'current_client_code';
  static const String _clientNameKey = 'client_name_';
  static const String _clientActiveKey = 'client_active_';
  
  static String? _currentClientCode;
  
  // Singleton pattern
  static final ClientContextService _instance = ClientContextService._internal();
  factory ClientContextService() => _instance;
  ClientContextService._internal();

  /// Obtiene el código del cliente actual
  String? get currentClientCode => _currentClientCode;

  /// Establece el cliente actual
  Future<void> setCurrentClient(String clientCode) async {
    _currentClientCode = clientCode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentClientKey, clientCode);
  }

  /// Carga el cliente actual desde SharedPreferences
  Future<void> loadCurrentClient() async {
    final prefs = await SharedPreferences.getInstance();
    _currentClientCode = prefs.getString(_currentClientKey);
  }

  /// Cierra sesión (limpia cliente actual)
  Future<void> logout() async {
    _currentClientCode = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentClientKey);
  }

  /// Registra un nuevo cliente en el sistema
  Future<void> registerClient(String clientCode, String clientName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('$_clientNameKey$clientCode', clientName);
    await prefs.setBool('$_clientActiveKey$clientCode', true);
  }

  /// Obtiene el nombre del cliente
  Future<String?> getClientName(String clientCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('$_clientNameKey$clientCode');
  }

  /// Verifica si un cliente existe y está activo
  Future<bool> isClientActive(String clientCode) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_clientActiveKey$clientCode') ?? false;
  }

  /// Obtiene la clave de almacenamiento específica para el cliente actual
  String getClientStorageKey(String baseKey) {
    if (_currentClientCode == null) {
      // Si no hay cliente activo, usar clave general para vendedores
      return '${baseKey}_general';
    }
    return '${baseKey}_$_currentClientCode';
  }

  /// Valida si hay un cliente activo
  void validateClientContext() {
    if (_currentClientCode == null) {
      throw Exception('Se requiere un cliente activo para esta operación');
    }
  }

  /// Obtiene todas las claves de clientes temporales
  Future<List<String>> getAllClientKeys() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    
    List<String> clientCodes = [];
    for (String key in keys) {
      if (key.startsWith(_clientNameKey)) {
        String clientCode = key.replaceFirst(_clientNameKey, '');
        clientCodes.add(clientCode);
      }
    }
    
    return clientCodes;
  }

  /// Elimina un cliente temporal específico
  Future<void> removeTemporaryClient(String clientCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_clientNameKey$clientCode');
    await prefs.remove('$_clientActiveKey$clientCode');
  }

  /// Elimina todos los clientes temporales
  Future<int> clearAllTemporaryClients() async {
    final clientCodes = await getAllClientKeys();
    int deletedCount = 0;
    
    for (String clientCode in clientCodes) {
      await removeTemporaryClient(clientCode);
      deletedCount++;
    }
    
    return deletedCount;
  }
}