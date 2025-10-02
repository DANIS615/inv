import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/client.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';
import '../services/client_service.dart';

class CreditPaymentScreen extends StatefulWidget {
  final String clientCode;
  final double invoiceTotal;
  final String? invoiceId;

  const CreditPaymentScreen({
    super.key,
    required this.clientCode,
    required this.invoiceTotal,
    this.invoiceId,
  });

  @override
  State<CreditPaymentScreen> createState() => _CreditPaymentScreenState();
}

class _CreditPaymentScreenState extends State<CreditPaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  final ClientService _clientService = ClientService();
  final TextEditingController _amountController = TextEditingController();
  
  Client? _client;
  CreditSummary? _creditSummary;
  PaymentType _selectedPaymentType = PaymentType.full;
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final TextEditingController _referenceController = TextEditingController();
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadClientData();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _loadClientData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar información del cliente
      final client = await _clientService.getClientByCode(widget.clientCode);
      if (client != null) {
        setState(() {
          _client = client;
        });

        // Cargar resumen de crédito
        final summary = await _paymentService.getClientCreditSummary(client.id.toString());
        setState(() {
          _creditSummary = summary;
        });

        // Establecer monto por defecto
        if (_selectedPaymentType == PaymentType.full) {
          _amountController.text = widget.invoiceTotal.toStringAsFixed(2);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: $e'),
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

  void _onPaymentTypeChanged(PaymentType? value) {
    if (value != null) {
      setState(() {
        _selectedPaymentType = value;
        if (value == PaymentType.full) {
          _amountController.text = widget.invoiceTotal.toStringAsFixed(2);
        } else if (value == PaymentType.partial) {
          _amountController.text = '';
        }
      });
    }
  }

  Future<void> _processPayment() async {
    if (_client == null) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un monto válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (amount > widget.invoiceTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El pago no puede ser mayor al monto total'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result = await _paymentService.processPayment(
        clientId: _client!.id.toString(),
        clientCode: _client!.code,
        clientName: _client!.name,
        totalAmount: widget.invoiceTotal,
        paymentAmount: amount,
        paymentType: _selectedPaymentType,
        paymentMethod: _selectedPaymentMethod,
        description: 'Pago de factura ${widget.invoiceId ?? 'N/A'}',
        invoiceId: widget.invoiceId,
        reference: _referenceController.text.trim().isNotEmpty 
            ? _referenceController.text.trim() 
            : null,
      );

      if (mounted) {
        if (result.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.green,
            ),
          );

          // Recargar datos
          await _loadClientData();

          // Mostrar resultado del pago
          _showPaymentResult(result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar pago: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _showPaymentResult(PaymentResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              result.success ? Icons.check_circle : Icons.error,
              color: result.success ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(result.success ? 'Pago Procesado' : 'Error en Pago'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(result.message),
            if (result.payment != null) ...[
              const SizedBox(height: 16),
              const Divider(),
              Text('Detalles del Pago:'),
              const SizedBox(height: 8),
              _buildSafeRow('Cliente:', result.payment!.clientName),
              _buildSafeRow('Monto Pagado:', 'RD\$${result.payment!.amount.toStringAsFixed(2)}'),
              _buildSafeRow('Monto Total:', 'RD\$${result.payment!.totalAmount.toStringAsFixed(2)}'),
              _buildSafeRow('Tipo de Pago:', _getPaymentTypeLabel(result.payment!.paymentType)),
              _buildSafeRow('Método de Pago:', _getPaymentMethodLabel(result.payment!.paymentMethod)),
              if (result.payment!.reference != null)
                _buildSafeRow('Referencia:', result.payment!.reference!),
              _buildSafeRow('Fecha:', _formatDateTime(result.payment!.createdAt)),
              if (result.remainingBalance != null && result.remainingBalance! > 0)
                _buildSafeRow('Saldo Pendiente:', 'RD\$${result.remainingBalance!.toStringAsFixed(2)}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
          if (result.success)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Cerrar diálogo
                Navigator.of(context).pop(true); // Volver a la pantalla anterior con resultado exitoso
              },
              child: const Text('Finalizar'),
            ),
        ],
      ),
    );
  }

  Widget _buildSafeRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(value),
        ],
      ),
    );
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

  String _getPaymentMethodLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Efectivo';
      case PaymentMethod.transfer:
        return 'Transferencia Bancaria';
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

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _getReferenceLabel(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transfer:
        return 'Número de Transferencia';
      case PaymentMethod.check:
        return 'Número de Cheque';
      case PaymentMethod.creditCard:
        return 'Últimos 4 dígitos';
      case PaymentMethod.debitCard:
        return 'Últimos 4 dígitos';
      case PaymentMethod.mobilePayment:
        return 'Número de Transacción';
      case PaymentMethod.other:
        return 'Referencia';
      case PaymentMethod.cash:
        return '';
    }
  }

  String _getReferenceHint(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.transfer:
        return 'Ej: TRF123456789';
      case PaymentMethod.check:
        return 'Ej: 000123456';
      case PaymentMethod.creditCard:
        return 'Ej: ****1234';
      case PaymentMethod.debitCard:
        return 'Ej: ****5678';
      case PaymentMethod.mobilePayment:
        return 'Ej: PM789012345';
      case PaymentMethod.other:
        return 'Ej: REF001';
      case PaymentMethod.cash:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_client == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
          backgroundColor: Colors.red,
        ),
        body: const Center(
          child: Text('Cliente no encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Pago'),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del cliente
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.person,
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Cliente: ${_client!.name}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text('Código: ${_client!.code}'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          _client!.accountType == AccountType.credito 
                              ? Icons.account_balance_wallet 
                              : Icons.payment,
                          size: 16,
                          color: _client!.accountType == AccountType.credito 
                              ? Colors.blue[700] 
                              : Colors.green[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Tipo: ${_client!.accountType == AccountType.credito ? 'Crédito' : 'Contado'}',
                          style: TextStyle(
                            color: _client!.accountType == AccountType.credito 
                                ? Colors.blue[700] 
                                : Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    if (_creditSummary != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Saldo actual: RD\$${_creditSummary!.pendingBalance.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _creditSummary!.pendingBalance > 0 
                              ? Colors.orange[700] 
                              : Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Información de la factura
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información de la Factura',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSafeRow('Monto Total:', 'RD\$${widget.invoiceTotal.toStringAsFixed(2)}'),
                    if (widget.invoiceId != null)
                      _buildSafeRow('ID Factura:', widget.invoiceId!),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tipo de pago
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tipo de Pago',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<PaymentType>(
                      title: const Text('Pago Completo'),
                      subtitle: const Text('Pagar el monto total de la factura'),
                      value: PaymentType.full,
                      groupValue: _selectedPaymentType,
                      onChanged: _onPaymentTypeChanged,
                    ),
                    if (_client!.accountType == AccountType.credito)
                      RadioListTile<PaymentType>(
                        title: const Text('Pago Parcial'),
                        subtitle: const Text('Pagar solo una parte del monto total'),
                        value: PaymentType.partial,
                        groupValue: _selectedPaymentType,
                        onChanged: _onPaymentTypeChanged,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Método de pago
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Método de Pago',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<PaymentMethod>(
                      value: _selectedPaymentMethod,
                      decoration: const InputDecoration(
                        labelText: 'Seleccionar método de pago',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.payment),
                      ),
                      items: PaymentMethod.values.map((method) {
                        return DropdownMenuItem(
                          value: method,
                          child: Text(_getPaymentMethodLabel(method)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPaymentMethod = value;
                          });
                        }
                      },
                    ),
                    if (_selectedPaymentMethod != PaymentMethod.cash) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _referenceController,
                        decoration: InputDecoration(
                          labelText: _getReferenceLabel(_selectedPaymentMethod),
                          hintText: _getReferenceHint(_selectedPaymentMethod),
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.receipt),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Monto del pago
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Monto del Pago',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _amountController,
                      decoration: const InputDecoration(
                        labelText: 'Monto a pagar',
                        prefixText: 'RD\$ ',
                        border: OutlineInputBorder(),
                        suffixIcon: Icon(Icons.attach_money),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      enabled: _selectedPaymentType == PaymentType.partial,
                    ),
                    if (_selectedPaymentType == PaymentType.partial) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Máximo: RD\$${widget.invoiceTotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Botón de procesar pago
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _processPayment,
                icon: _isProcessing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.payment),
                label: Text(_isProcessing ? 'Procesando...' : 'Procesar Pago'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
