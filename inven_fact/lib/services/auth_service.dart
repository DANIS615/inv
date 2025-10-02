import 'package:shared_preferences/shared_preferences.dart';
import '../models/seller.dart';
import 'seller_service.dart';

class AuthService {
  static const String _sellerKey = 'seller_logged_in';
  static const String _sellerNameKey = 'seller_name';
  static const String _sellerIdKey = 'seller_id';
  static const String _isFirstLoginKey = 'is_first_login';
  static const String _showDefaultCredsKey = 'show_default_creds';
  static const String _rememberMeKey = 'remember_me';
  
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SellerService _sellerService = SellerService();

  bool _isSellerLoggedIn = false;
  String? _sellerName;
  String? _sellerId;
  bool _isFirstLogin = false;
  Seller? _currentSeller;

  bool get isSellerLoggedIn => _isSellerLoggedIn;
  String? get sellerName => _sellerName;
  String? get sellerId => _sellerId;
  bool get isFirstLogin => _isFirstLogin;
  Seller? get currentSeller => _currentSeller;

  /// Inicia sesión como vendedor
  Future<bool> loginSeller(String sellerId, String password) async {
    try {
      final seller = await _sellerService.authenticateSeller(sellerId, password);
      
      if (seller != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_sellerKey, true);
        await prefs.setString(_sellerNameKey, seller.name);
        await prefs.setString(_sellerIdKey, seller.id);
        await prefs.setBool(_isFirstLoginKey, seller.isFirstLogin);
        
        _isSellerLoggedIn = true;
        _sellerName = seller.name;
        _sellerId = seller.id;
        _isFirstLogin = seller.isFirstLogin;
        _currentSeller = seller;
        
        // Actualizar último login
        await _sellerService.updateLastLogin(sellerId);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Carga el estado de autenticación desde SharedPreferences
  Future<void> loadAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final remember = prefs.getBool(_rememberMeKey) ?? false;
      final logged = prefs.getBool(_sellerKey) ?? false;

      if (remember && logged) {
        _isSellerLoggedIn = true;
        _sellerName = prefs.getString(_sellerNameKey);
        _sellerId = prefs.getString(_sellerIdKey);
        _isFirstLogin = prefs.getBool(_isFirstLoginKey) ?? false;
        if (_sellerId != null) {
          // Intentar cargar el vendedor actual
          _currentSeller = await _sellerService.getSellerById(_sellerId!);
        }
      } else {
        _isSellerLoggedIn = false;
        _sellerName = null;
        _sellerId = null;
        _isFirstLogin = false;
        _currentSeller = null;
      }
    } catch (e) {
      _isSellerLoggedIn = false;
      _sellerName = null;
      _sellerId = null;
      _isFirstLogin = false;
      _currentSeller = null;
    }
  }

  /// Cierra sesión del vendedor
  Future<void> logoutSeller() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sellerKey);
      await prefs.remove(_sellerNameKey);
      await prefs.remove(_sellerIdKey);
      await prefs.remove(_isFirstLoginKey);
      
      _isSellerLoggedIn = false;
      _sellerName = null;
      _sellerId = null;
      _isFirstLogin = false;
      _currentSeller = null;
    } catch (e) {
      // Error al cerrar sesión, pero continuar
    }
  }

  /// Cambia la contraseña del vendedor actual
  Future<bool> changePassword(String newPassword) async {
    try {
      if (_sellerId != null) {
        await _sellerService.changePassword(_sellerId!, newPassword);
        _isFirstLogin = false;
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cambia el nombre del vendedor actual
  Future<bool> changeSellerName(String newName) async {
    try {
      if (_sellerId != null) {
        await _sellerService.updateSellerName(_sellerId!, newName);
        
        // Actualizar el estado actual
        _sellerName = newName;
        
        // Actualizar también en SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_sellerNameKey, newName);
        
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Cambia el ID del vendedor actual
  Future<bool> changeSellerId(String newId) async {
    try {
      if (_sellerId != null) {
        // Verificar que el nuevo ID no esté en uso
        final existingSeller = await _sellerService.getSellerById(newId);
        if (existingSeller != null && existingSeller.id != _sellerId) {
          return false; // ID ya existe
        }
        
        // Obtener el vendedor actual
        final currentSeller = await _sellerService.getSellerById(_sellerId!);
        if (currentSeller != null) {
          // Crear un nuevo vendedor con el nuevo ID
          final newSeller = Seller(
            id: newId,
            name: currentSeller.name,
            password: currentSeller.password,
            isFirstLogin: currentSeller.isFirstLogin,
            createdAt: currentSeller.createdAt,
            lastLogin: currentSeller.lastLogin,
            isActive: currentSeller.isActive,
          );
          
          // Agregar el nuevo vendedor
          await _sellerService.addSeller(newSeller);
          
          // Eliminar el vendedor viejo
          await _sellerService.deleteSeller(_sellerId!);
          
          // Actualizar el estado actual
          _sellerId = newId;
          
          // Actualizar también en SharedPreferences
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_sellerIdKey, newId);
          
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Actualiza el nombre del vendedor en la sesión actual
  void updateCurrentSellerName(String newName) {
    _sellerName = newName;
  }

  /// Actualiza el ID del vendedor en la sesión actual
  void updateCurrentSellerId(String newId) {
    _sellerId = newId;
  }

  /// Verifica si hay un vendedor autenticado
  bool isAuthenticated() {
    return _isSellerLoggedIn && _sellerName != null && _sellerId != null;
  }

  /// Devuelve el último ID de vendedor almacenado (para prellenar login)
  Future<String?> getLastSellerId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sellerIdKey);
  }

  /// Indica si se debe mostrar el mensaje de credenciales por defecto (primera vez)
  Future<bool> getShowDefaultCreds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showDefaultCredsKey) ?? true;
  }

  /// Desactiva el mensaje de credenciales por defecto (luego del primer login)
  Future<void> disableDefaultCredsMessage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDefaultCredsKey, false);
  }

  /// Guarda la preferencia "mantener sesión iniciada"
  Future<void> setRememberMe(bool remember) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, remember);
  }

  /// Obtiene la preferencia "mantener sesión iniciada"
  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }
}
