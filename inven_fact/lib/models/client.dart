enum AccountType { contado, credito }

class Client {
  final int? id;
  final String name;
  final String code;
  final AccountType accountType;
  final double pendingBalance;
  final DateTime? lastPurchase;
  final bool isActive;
  final String? rnc;
  final String? cedula;
  final String? direccion;
  final String? telefono;
  final String? email;

  Client({
    this.id,
    required this.name,
    required this.code,
    this.accountType = AccountType.contado,
    this.pendingBalance = 0.0,
    this.lastPurchase,
    this.isActive = true,
    this.rnc,
    this.cedula,
    this.direccion,
    this.telefono,
    this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'account_type': accountType.name,
      'pending_balance': pendingBalance,
      'last_purchase': lastPurchase?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
      'rnc': rnc,
      'cedula': cedula,
      'direccion': direccion,
      'telefono': telefono,
      'email': email,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      code: map['code'] ?? '',
      accountType: map['account_type'] == 'credito' || map['account_type'] == 'AccountType.credito'
          ? AccountType.credito 
          : AccountType.contado,
      pendingBalance: (map['pending_balance'] ?? 0.0).toDouble(),
      lastPurchase: map['last_purchase'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['last_purchase'])
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
      rnc: map['rnc'],
      cedula: map['cedula'],
      direccion: map['direccion'],
      telefono: map['telefono'],
      email: map['email'],
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? code,
    AccountType? accountType,
    double? pendingBalance,
    DateTime? lastPurchase,
    bool? isActive,
    String? rnc,
    String? cedula,
    String? direccion,
    String? telefono,
    String? email,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      accountType: accountType ?? this.accountType,
      pendingBalance: pendingBalance ?? this.pendingBalance,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      isActive: isActive ?? this.isActive,
      rnc: rnc ?? this.rnc,
      cedula: cedula ?? this.cedula,
      direccion: direccion ?? this.direccion,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
    );
  }
}
