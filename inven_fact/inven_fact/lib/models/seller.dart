class Seller {
  final String id;
  final String name;
  final String password;
  final bool isFirstLogin;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isActive;

  Seller({
    required this.id,
    required this.name,
    required this.password,
    this.isFirstLogin = true,
    required this.createdAt,
    this.lastLogin,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'password': password,
      'is_first_login': isFirstLogin ? 1 : 0,
      'created_at': createdAt.millisecondsSinceEpoch,
      'last_login': lastLogin?.millisecondsSinceEpoch,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory Seller.fromMap(Map<String, dynamic> map) {
    return Seller(
      id: map['id'],
      name: map['name'],
      password: map['password'],
      isFirstLogin: (map['is_first_login'] ?? 1) == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      lastLogin: map['last_login'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['last_login'])
          : null,
      isActive: (map['is_active'] ?? 1) == 1,
    );
  }

  Seller copyWith({
    String? id,
    String? name,
    String? password,
    bool? isFirstLogin,
    DateTime? createdAt,
    DateTime? lastLogin,
    bool? isActive,
  }) {
    return Seller(
      id: id ?? this.id,
      name: name ?? this.name,
      password: password ?? this.password,
      isFirstLogin: isFirstLogin ?? this.isFirstLogin,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
    );
  }
}
