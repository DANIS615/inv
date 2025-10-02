import 'package:flutter/material.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';
import '../models/payment.dart';
import '../models/client.dart';
import '../services/payment_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final String clientId;
  final String clientName;
  final String clientCode;
  final AccountType accountType;

  const PaymentHistoryScreen({
    super.key,
    required this.clientId,
    required this.clientName,
    required this.clientCode,
    required this.accountType,
  });

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  final PaymentService _paymentService = PaymentService();
  List<Payment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Widget _buildSummaryChip({required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(color: Colors.grey[700], fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final payments = await _paymentService.getClientPayments(widget.clientId);
      setState(() {
        _payments = payments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar pagos: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia';
      case PaymentMethod.check:
        return 'Cheque';
      case PaymentMethod.creditCard:
        return 'Tarjeta de Crédito';
      case PaymentMethod.debitCard:
        return 'Tarjeta de Débito';
      case PaymentMethod.mobilePayment:
        return 'Pago Móvil';
      case PaymentMethod.other:
        return 'Otro';
    }
  }

  String _getPaymentTypeLabel(PaymentType type) {
    switch (type) {
      case PaymentType.cash:
        return 'Efectivo';
      case PaymentType.partial:
        return 'Pago Parcial';
      case PaymentType.full:
        return 'Pago Completo';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getPaymentStatusColor(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.completed:
        return Colors.green;
      case PaymentStatus.pending:
        return Colors.orange;
      case PaymentStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getPaymentMethodIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.money;
      case PaymentMethod.transfer:
        return Icons.account_balance;
      case PaymentMethod.check:
        return Icons.receipt_long;
      case PaymentMethod.creditCard:
        return Icons.credit_card;
      case PaymentMethod.debitCard:
        return Icons.credit_card;
      case PaymentMethod.mobilePayment:
        return Icons.phone_android;
      case PaymentMethod.other:
        return Icons.payment;
    }
  }

  Widget _buildPaymentCard(Payment payment) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getPaymentStatusColor(payment.status).withOpacity(0.1),
          child: Icon(
            _getPaymentMethodIcon(payment.paymentMethod),
            color: _getPaymentStatusColor(payment.status),
          ),
        ),
        title: Text(
          'RD\$${payment.amount.toStringAsFixed(2)}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${_getPaymentMethodLabel(payment.paymentMethod)} - ${_getPaymentTypeLabel(payment.paymentType)}'),
            Text(
              _formatDateTime(payment.createdAt),
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
            if (payment.reference != null)
              Text(
                'Ref: ${payment.reference}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPaymentStatusColor(payment.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                payment.status.name.toUpperCase(),
                style: TextStyle(
                  color: _getPaymentStatusColor(payment.status),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Solo mostrar saldo para clientes de crédito
            if (payment.isPartialPayment && widget.accountType == AccountType.credito) ...[
              const SizedBox(height: 4),
              Text(
                'Saldo: RD\$${payment.remainingBalance.toStringAsFixed(2)}',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        onTap: () => _showPaymentDetails(payment),
      ),
    );
  }

  void _showPaymentDetails(Payment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Icon(
              _getPaymentMethodIcon(payment.paymentMethod),
              color: _getPaymentStatusColor(payment.status),
            ),
            const Text('Detalles del Pago'),
          ],
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Cliente:', payment.clientName),
                _buildDetailRow('Código:', payment.clientCode),
                _buildDetailRow('Monto Pagado:', 'RD\$${payment.amount.toStringAsFixed(2)}'),
                _buildDetailRow('Monto Total:', 'RD\$${payment.totalAmount.toStringAsFixed(2)}'),
                _buildDetailRow('Método de Pago:', _getPaymentMethodLabel(payment.paymentMethod)),
                _buildDetailRow('Tipo de Pago:', _getPaymentTypeLabel(payment.paymentType)),
                _buildDetailRow('Estado:', payment.status.name.toUpperCase()),
                _buildDetailRow('Fecha:', _formatDateTime(payment.createdAt)),
                if (payment.reference != null)
                  _buildDetailRow('Referencia:', payment.reference!),
                if (payment.invoiceId != null)
                  _buildDetailRow('ID Factura:', payment.invoiceId!),
                if (payment.description != null)
                  _buildDetailRow('Descripción:', payment.description!),
                // Solo mostrar saldo pendiente para clientes de crédito
                if (payment.isPartialPayment && widget.accountType == AccountType.credito)
                  _buildDetailRow('Saldo Pendiente:', 'RD\$${payment.remainingBalance.toStringAsFixed(2)}'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _printPaymentTicket(payment);
            },
            icon: const Icon(Icons.print),
            label: const Text('Imprimir'),
          ),
        ],
      ),
    );
  }

  Future<void> _printPaymentTicket(Payment payment) async {
    try {
      await SunmiPrinter.initPrinter();

      await SunmiPrinter.printText('RECIBO DE PAGO');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Cliente: ${payment.clientName}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Código: ${payment.clientCode}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Fecha: ${_formatDateTime(payment.createdAt)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Método: ${_getPaymentMethodLabel(payment.paymentMethod)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Tipo: ${_getPaymentTypeLabel(payment.paymentType)}');
      if (payment.reference != null) {
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText('Ref: ${payment.reference}');
      }

      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('------------------------------');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Pagado: RD\$${payment.amount.toStringAsFixed(2)}');
      await SunmiPrinter.lineWrap(1);
      await SunmiPrinter.printText('Total Factura: RD\$${payment.totalAmount.toStringAsFixed(2)}');
      // Solo mostrar saldo restante para clientes de crédito
      if (payment.isPartialPayment && widget.accountType == AccountType.credito) {
        await SunmiPrinter.lineWrap(1);
        await SunmiPrinter.printText('Saldo Restante: RD\$${payment.remainingBalance.toStringAsFixed(2)}');
      }

      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.printText('Gracias por su pago');
      await SunmiPrinter.lineWrap(3);
      await SunmiPrinter.cutPaper();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al imprimir: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Historial de Pagos - ${widget.clientName}'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPayments,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _payments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.payment,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay pagos registrados',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Los pagos aparecerán aquí cuando se procesen',
                        style: TextStyle(
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Resumen de pagos
                    Container(
                      padding: const EdgeInsets.all(16),
                      color: Colors.grey[50],
                      child: Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceAround,
                        children: [
                          _buildSummaryChip(
                            title: 'Total Pagos',
                            value: '${_payments.length}',
                            color: Colors.blue,
                          ),
                          _buildSummaryChip(
                            title: 'Total Pagado',
                            value: 'RD\$${_payments.fold(0.0, (sum, p) => sum + p.amount).toStringAsFixed(2)}',
                            color: Colors.green,
                          ),
                          // Solo mostrar saldo pendiente para clientes de crédito
                          if (widget.accountType == AccountType.credito)
                            _buildSummaryChip(
                              title: 'Saldo Pendiente',
                              value: 'RD\$${_payments.fold(0.0, (sum, p) => sum + p.remainingBalance).toStringAsFixed(2)}',
                              color: Colors.orange,
                            ),
                        ],
                      ),
                    ),
                    // Lista de pagos
                    Expanded(
                      child: ListView.builder(
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          return _buildPaymentCard(_payments[index]);
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
