class InvoiceItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final String priceType; // 'wholesale', 'retail', 'distribution'
  
  InvoiceItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.priceType,
  });
  
  double get total => quantity * unitPrice;
  
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'priceType': priceType,
    };
  }
  
  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      productId: json['productId'],
      productName: json['productName'],
      quantity: json['quantity'],
      unitPrice: json['unitPrice'].toDouble(),
      priceType: json['priceType'],
    );
  }
}

class Invoice {
  final String id;
  final String customerName;
  final String customerEmail;
  final DateTime createdAt;
  final List<InvoiceItem> items;
  final double subtotal;
  final double tax;
  final double total;
  
  Invoice({
    required this.id,
    required this.customerName,
    required this.customerEmail,
    required this.createdAt,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.total,
  });
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'createdAt': createdAt.toIso8601String(),
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'total': total,
    };
  }
  
  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      id: json['id'],
      customerName: json['customerName'],
      customerEmail: json['customerEmail'],
      createdAt: DateTime.parse(json['createdAt']),
      items: (json['items'] as List)
          .map((item) => InvoiceItem.fromJson(item))
          .toList(),
      subtotal: json['subtotal'].toDouble(),
      tax: json['tax'].toDouble(),
      total: json['total'].toDouble(),
    );
  }
}