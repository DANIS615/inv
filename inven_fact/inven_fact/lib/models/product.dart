class Product {
  final String id;
  final String name;
  final String description;
  final double wholesalePrice; // Precio al por mayor
  final double retailPrice; // Precio al detalle
  final double distributionPrice; // Precio de distribución
  final int quantity;
  final String category;
  final DateTime createdAt;
  final String? imageUrl; // Nueva propiedad para la imagen
  final String? barcode; // Código de barras del producto

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.wholesalePrice,
    required this.retailPrice,
    required this.distributionPrice,
    required this.quantity,
    required this.category,
    required this.createdAt,
    this.imageUrl, // Opcional
    this.barcode, // Opcional
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'wholesalePrice': wholesalePrice,
      'retailPrice': retailPrice,
      'distributionPrice': distributionPrice,
      'quantity': quantity,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'imageUrl': imageUrl, // Incluir en JSON
      'barcode': barcode, // Incluir código de barras en JSON
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      wholesalePrice: json['wholesalePrice'].toDouble(),
      retailPrice: json['retailPrice'].toDouble(),
      distributionPrice: json['distributionPrice'].toDouble(),
      quantity: json['quantity'],
      category: json['category'],
      createdAt: DateTime.parse(json['createdAt']),
      imageUrl: json['imageUrl'], // Cargar desde JSON
      barcode: json['barcode'], // Cargar código de barras desde JSON
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? wholesalePrice,
    double? retailPrice,
    double? distributionPrice,
    int? quantity,
    String? category,
    DateTime? createdAt,
    String? imageUrl,
    String? barcode,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      retailPrice: retailPrice ?? this.retailPrice,
      distributionPrice: distributionPrice ?? this.distributionPrice,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
    );
  }
}
