import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment.dart';
import '../models/client.dart';
import 'client_service.dart';

class PaymentService {
  static const String _paymentsKey = 'payments';
  static const String _creditSummariesKey = 'credit_summaries';
  static const String _clientPaymentsPrefix = 'client_payments_';
  static const int _maxPaymentsPerClient = 10;

  final ClientService _clientService = ClientService();

  // Guardar un pago
  Future<void> savePayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Guardar en historial general (mantener compatibilidad)
    final paymentsJson = prefs.getString(_paymentsKey) ?? '[]';
    final List<dynamic> paymentsList = json.decode(paymentsJson);
    paymentsList.add(payment.toJson());
    await prefs.setString(_paymentsKey, json.encode(paymentsList));
    
    // Guardar en historial específico del cliente
    await _saveClientPayment(payment);
    
    // Actualizar el resumen de crédito del cliente
    await _updateClientCreditSummary(payment);
    
    // Pago guardado exitosamente
  }

  // Obtener todos los pagos
  Future<List<Payment>> getPayments() async {
    final prefs = await SharedPreferences.getInstance();
    final paymentsJson = prefs.getString(_paymentsKey) ?? '[]';
    final List<dynamic> paymentsList = json.decode(paymentsJson);
    
    return paymentsList.map((json) => Payment.fromJson(json)).toList();
  }

  // Obtener pagos de un cliente específico
  Future<List<Payment>> getClientPayments(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final clientKey = '$_clientPaymentsPrefix$clientId';
    final clientPaymentsJson = prefs.getString(clientKey) ?? '[]';
    final List<dynamic> clientPaymentsList = json.decode(clientPaymentsJson);
    
    final payments = clientPaymentsList.map((json) => Payment.fromJson(json)).toList();
    // Ordenar por fecha más reciente primero
    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Pagos encontrados para cliente
    return payments;
  }

  // Obtener resumen de crédito de un cliente
  Future<CreditSummary?> getClientCreditSummary(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getString(_creditSummariesKey) ?? '{}';
    final Map<String, dynamic> summaries = json.decode(summariesJson);
    
    if (summaries.containsKey(clientId)) {
      return CreditSummary.fromJson(summaries[clientId]);
    }
    
    return null;
  }

  // Obtener todos los resúmenes de crédito
  Future<List<CreditSummary>> getAllCreditSummaries() async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getString(_creditSummariesKey) ?? '{}';
    final Map<String, dynamic> summaries = json.decode(summariesJson);
    
    return summaries.values
        .map((json) => CreditSummary.fromJson(json))
        .toList();
  }

  // Procesar un pago
  Future<PaymentResult> processPayment({
    required String clientId,
    required String clientCode,
    required String clientName,
    required double totalAmount,
    required double paymentAmount,
    required PaymentType paymentType,
    PaymentMethod paymentMethod = PaymentMethod.cash,
    String? description,
    String? invoiceId,
    String? reference,
    bool increaseDebtByInvoiceTotal = false,
  }) async {
    try {
      // Validar que el cliente existe
      final clientIdInt = int.tryParse(clientId);
      if (clientIdInt == null) {
        return PaymentResult(
          success: false,
          message: 'ID de cliente inválido',
        );
      }
      
      final client = await _clientService.getClientById(clientIdInt);
      if (client == null) {
        return PaymentResult(
          success: false,
          message: 'Cliente no encontrado',
        );
      }

      // Validar que el cliente es de crédito si es pago parcial
      if (paymentType == PaymentType.partial && client.accountType != AccountType.credito) {
        return PaymentResult(
          success: false,
          message: 'Solo clientes de crédito pueden hacer pagos parciales',
        );
      }

      // Validar monto del pago
      if (paymentAmount <= 0) {
        return PaymentResult(
          success: false,
          message: 'El monto del pago debe ser mayor a 0',
        );
      }

      if (paymentAmount > totalAmount) {
        return PaymentResult(
          success: false,
          message: 'El pago no puede ser mayor al monto total',
        );
      }

      // Crear el pago
      final payment = Payment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        clientId: clientId,
        clientCode: clientCode,
        clientName: clientName,
        amount: paymentAmount,
        totalAmount: totalAmount,
        paymentType: paymentType,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        description: description,
        invoiceId: invoiceId,
        reference: reference,
      );

      // Guardar el pago
      await savePayment(payment);

      // Actualizar el saldo pendiente del cliente
      // Si es una factura a crédito, se suma el total de la factura y se resta lo pagado.
      // Si es un pago directo a cuenta, solo se resta lo pagado.
      final double rawNewBalance = client.pendingBalance 
          + (increaseDebtByInvoiceTotal ? totalAmount : 0) 
          - paymentAmount;
      final newBalance = rawNewBalance < 0 ? 0.0 : rawNewBalance;
      final updatedClient = client.copyWith(
        pendingBalance: newBalance,
        lastPurchase: DateTime.now(),
      );
      await _clientService.updateClient(updatedClient);

      return PaymentResult(
        success: true,
        message: payment.isFullPayment 
            ? 'Pago completado exitosamente'
            : 'Pago parcial registrado. Saldo pendiente del cliente: RD\$${newBalance.toStringAsFixed(2)}',
        payment: payment,
        remainingBalance: newBalance,
      );

    } catch (e) {
      return PaymentResult(
        success: false,
        message: 'Error al procesar el pago: $e',
      );
    }
  }

  // Actualizar resumen de crédito del cliente
  Future<void> _updateClientCreditSummary(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final summariesJson = prefs.getString(_creditSummariesKey) ?? '{}';
    final Map<String, dynamic> summaries = json.decode(summariesJson);

    // Obtener pagos del cliente
    final clientPayments = await getClientPayments(payment.clientId);
    
    // Calcular totales
    double totalDebt = 0;
    double totalPaid = 0;
    DateTime? lastPayment;
    DateTime? lastPurchase;

    for (final p in clientPayments) {
      totalDebt += p.totalAmount;
      totalPaid += p.amount;
      
      if (lastPayment == null || p.createdAt.isAfter(lastPayment)) {
        lastPayment = p.createdAt;
      }
    }

    final pendingBalance = totalDebt - totalPaid;

    // Obtener información del cliente
    final clientIdInt = int.tryParse(payment.clientId);
    if (clientIdInt != null) {
      final client = await _clientService.getClientById(clientIdInt);
      if (client != null && client.lastPurchase != null) {
        lastPurchase = client.lastPurchase;
      }
    }

    // Crear o actualizar resumen
    final summary = CreditSummary(
      clientId: payment.clientId,
      clientCode: payment.clientCode,
      clientName: payment.clientName,
      totalDebt: totalDebt,
      totalPaid: totalPaid,
      pendingBalance: pendingBalance,
      totalTransactions: clientPayments.length,
      lastPayment: lastPayment,
      lastPurchase: lastPurchase,
    );

    summaries[payment.clientId] = summary.toJson();
    await prefs.setString(_creditSummariesKey, json.encode(summaries));
  }

  // Obtener clientes con deuda pendiente
  Future<List<CreditSummary>> getClientsWithDebt() async {
    final summaries = await getAllCreditSummaries();
    return summaries.where((summary) => summary.pendingBalance > 0).toList();
  }

  // Limpiar datos de pagos (para testing)
  Future<void> clearAllPayments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_paymentsKey);
    await prefs.remove(_creditSummariesKey);
    print('🗑️ PaymentService: Todos los pagos eliminados');
  }

  // Guardar pago en historial específico del cliente
  Future<void> _saveClientPayment(Payment payment) async {
    final prefs = await SharedPreferences.getInstance();
    final clientKey = '$_clientPaymentsPrefix${payment.clientId}';
    
    // Obtener pagos existentes del cliente
    final clientPaymentsJson = prefs.getString(clientKey) ?? '[]';
    final List<dynamic> clientPaymentsList = json.decode(clientPaymentsJson);
    
    // Agregar el nuevo pago
    clientPaymentsList.add(payment.toJson());
    
    // Convertir a objetos Payment para ordenar por fecha
    final payments = clientPaymentsList.map((json) => Payment.fromJson(json)).toList();
    payments.sort((a, b) => b.createdAt.compareTo(a.createdAt)); // Más recientes primero
    
    // Mantener solo las últimas 10 facturas
    final paymentsToKeep = payments.take(_maxPaymentsPerClient).toList();
    
    if (payments.length > _maxPaymentsPerClient) {
      final removedCount = payments.length - _maxPaymentsPerClient;
      // Facturas viejas eliminadas automáticamente
    }
    
    // Guardar las facturas limitadas
    final limitedPaymentsList = paymentsToKeep.map((p) => p.toJson()).toList();
    await prefs.setString(clientKey, json.encode(limitedPaymentsList));
    
    // Historial del cliente actualizado
  }
}

class PaymentResult {
  final bool success;
  final String message;
  final Payment? payment;
  final double? remainingBalance;

  PaymentResult({
    required this.success,
    required this.message,
    this.payment,
    this.remainingBalance,
  });
}
