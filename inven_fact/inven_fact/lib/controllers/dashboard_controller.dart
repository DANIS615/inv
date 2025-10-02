import 'package:flutter/foundation.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  final DashboardService _service;
  DashboardMetrics? _metrics;
  bool _loading = false;

  DashboardController(this._service);

  DashboardMetrics? get metrics => _metrics;
  bool get isLoading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    try {
      _metrics = await _service.computeMetrics();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}


