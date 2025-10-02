import '../services/client_service.dart';
import '../services/inventory_service.dart';
import '../models/client.dart';
import '../models/product.dart';

class DashboardMetrics {
  final int totalClients;
  final int totalProducts;
  final int lowStockProducts;
  final int outOfStockProducts;
  final int creditClients;
  final double totalInventoryValue;

  DashboardMetrics({
    required this.totalClients,
    required this.totalProducts,
    required this.lowStockProducts,
    required this.outOfStockProducts,
    required this.creditClients,
    required this.totalInventoryValue,
  });
}

class DashboardService {
  final ClientService _clientService = ClientService();
  final InventoryService _inventoryService = InventoryService();

  Future<DashboardMetrics> computeMetrics() async {
    final List<Client> clients = await _clientService.getClients();
    final List<Product> products = await _inventoryService.getProducts();

    final int totalClients = clients.length;
    final int totalProducts = products.length;
    final int lowStockProducts = products.where((p) => p.quantity < 10).length;
    final int outOfStockProducts = products.where((p) => p.quantity == 0).length;
    final int creditClients = clients.where((c) => c.accountType == AccountType.credito).length;
    final double totalInventoryValue = products.fold<double>(0.0, (sum, p) => sum + p.retailPrice * p.quantity);

    return DashboardMetrics(
      totalClients: totalClients,
      totalProducts: totalProducts,
      lowStockProducts: lowStockProducts,
      outOfStockProducts: outOfStockProducts,
      creditClients: creditClients,
      totalInventoryValue: totalInventoryValue,
    );
  }
}


