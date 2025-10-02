import 'dart:async';

/// EventBus simple para comunicar cambios entre pantallas
/// Eventos sugeridos: 'clientsChanged', 'inventoryChanged', 'paymentsChanged'
class EventBus {
  EventBus._internal();
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;

  final StreamController<String> _controller = StreamController<String>.broadcast();

  /// Emitir un evento por nombre
  void fire(String eventName) {
    _controller.add(eventName);
  }

  /// Escuchar un evento específico
  Stream<String> on(String eventName) {
    return _controller.stream.where((e) => e == eventName);
  }

  /// Escuchar todos los eventos (si se requiere)
  Stream<String> get stream => _controller.stream;

  void dispose() {
    _controller.close();
  }
}


