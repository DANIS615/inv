enum PaymentType { 
  cash,        // Efectivo
  partial,     // Pago parcial
  full         // Pago completo
}

enum PaymentMethod {
  cash,           // Efectivo
  transfer,       // Transferencia bancaria
  check,          // Cheque
  creditCard,     // Tarjeta de crédito
  debitCard,      // Tarjeta de débito
  mobilePayment,  // Pago móvil
  other           // Otro
}

enum PaymentStatus {
  pending,     // Pendiente
  completed,   // Completado
  cancelled    // Cancelado
}

class Payment {
  final String id;
  final String clientId;
  final String clientCode;
  final String clientName;
  final double amount;
  final double totalAmount; // Monto total de la factura
  final PaymentType paymentType;
  final PaymentMethod paymentMethod;
  final PaymentStatus status;
  final DateTime createdAt;
  final String? description;
  final String? invoiceId; // ID de la factura relacionada
  final String? reference; // Referencia del pago (número de transferencia, etc.)

  Payment({
    required this.id,
    required this.clientId,
    required this.clientCode,
    required this.clientName,
    required this.amount,
    required this.totalAmount,
    required this.paymentType,
    this.paymentMethod = PaymentMethod.cash,
    this.status = PaymentStatus.completed,
    required this.createdAt,
    this.description,
    this.invoiceId,
    this.reference,
  });

  // Calcular el saldo pendiente después del pago
  double get remainingBalance => totalAmount - amount;

  // Verificar si el pago es completo
  bool get isFullPayment => amount >= totalAmount;

  // Verificar si el pago es parcial
  bool get isPartialPayment => amount < totalAmount && amount > 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'clientId': clientId,
      'clientCode': clientCode,
      'clientName': clientName,
      'amount': amount,
      'totalAmount': totalAmount,
      'paymentType': paymentType.name,
      'paymentMethod': paymentMethod.name,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'description': description,
      'invoiceId': invoiceId,
      'reference': reference,
    };
  }

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'],
      clientId: json['clientId'],
      clientCode: json['clientCode'],
      clientName: json['clientName'],
      amount: json['amount'].toDouble(),
      totalAmount: json['totalAmount'].toDouble(),
      paymentType: PaymentType.values.firstWhere(
        (e) => e.name == json['paymentType'],
        orElse: () => PaymentType.cash,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.name == json['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PaymentStatus.completed,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      description: json['description'],
      invoiceId: json['invoiceId'],
      reference: json['reference'],
    );
  }

  Payment copyWith({
    String? id,
    String? clientId,
    String? clientCode,
    String? clientName,
    double? amount,
    double? totalAmount,
    PaymentType? paymentType,
    PaymentMethod? paymentMethod,
    PaymentStatus? status,
    DateTime? createdAt,
    String? description,
    String? invoiceId,
    String? reference,
  }) {
    return Payment(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      clientCode: clientCode ?? this.clientCode,
      clientName: clientName ?? this.clientName,
      amount: amount ?? this.amount,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      invoiceId: invoiceId ?? this.invoiceId,
      reference: reference ?? this.reference,
    );
  }
}

class CreditSummary {
  final String clientId;
  final String clientCode;
  final String clientName;
  final double totalDebt;        // Deuda total
  final double totalPaid;        // Total pagado
  final double pendingBalance;   // Saldo pendiente
  final int totalTransactions;   // Total de transacciones
  final DateTime? lastPayment;   // Último pago
  final DateTime? lastPurchase;  // Última compra

  CreditSummary({
    required this.clientId,
    required this.clientCode,
    required this.clientName,
    required this.totalDebt,
    required this.totalPaid,
    required this.pendingBalance,
    required this.totalTransactions,
    this.lastPayment,
    this.lastPurchase,
  });

  // Calcular porcentaje pagado
  double get paymentPercentage {
    if (totalDebt == 0) return 100.0;
    return (totalPaid / totalDebt) * 100;
  }

  // Verificar si está al día
  bool get isUpToDate => pendingBalance <= 0;

  Map<String, dynamic> toJson() {
    return {
      'clientId': clientId,
      'clientCode': clientCode,
      'clientName': clientName,
      'totalDebt': totalDebt,
      'totalPaid': totalPaid,
      'pendingBalance': pendingBalance,
      'totalTransactions': totalTransactions,
      'lastPayment': lastPayment?.toIso8601String(),
      'lastPurchase': lastPurchase?.toIso8601String(),
    };
  }

  factory CreditSummary.fromJson(Map<String, dynamic> json) {
    return CreditSummary(
      clientId: json['clientId'],
      clientCode: json['clientCode'],
      clientName: json['clientName'],
      totalDebt: json['totalDebt'].toDouble(),
      totalPaid: json['totalPaid'].toDouble(),
      pendingBalance: json['pendingBalance'].toDouble(),
      totalTransactions: json['totalTransactions'],
      lastPayment: json['lastPayment'] != null 
          ? DateTime.parse(json['lastPayment'])
          : null,
      lastPurchase: json['lastPurchase'] != null 
          ? DateTime.parse(json['lastPurchase'])
          : null,
    );
  }
}
