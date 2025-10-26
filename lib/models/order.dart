class OrderImage {
  final String src;

  OrderImage({required this.src});

  factory OrderImage.fromJson(Map<String, dynamic> json) {
    return OrderImage(
      src: json['src'] ?? json['image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'src': src};
  }
}

class OrderItem {
  final int id;
  final String name;
  final int productId;
  final int quantity;
  final double price;
  final OrderImage? image;
  final String warehouse;

  OrderItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.quantity,
    required this.price,
    this.image,
    required this.warehouse,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    final quantity = json['quantity'] ?? 0;
    final priceString = json['price']?.toString() ?? '0.0';
    final unitPrice = double.tryParse(priceString) ?? 0.0;
    
    // Create image from image_url
    OrderImage? image;
    final imageUrl = json['image_url'];
    if (imageUrl != null && imageUrl != false && imageUrl.toString().isNotEmpty) {
      image = OrderImage(src: imageUrl.toString());
    }
    
    return OrderItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      quantity: quantity,
      price: unitPrice,
      image: image,
      warehouse: json['warehouse']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_id': productId,
      'quantity': quantity,
      'price': price,
      'image_url': image?.src,
      'warehouse': warehouse,
    };
  }

  // Helper getters
  double get total => price * quantity;
  String get totalFormatted => total.toStringAsFixed(2);
}

class Billing {
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String address;
  final String nip;

  Billing({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.address,
    required this.nip,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      nip: json['nip'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'address': address,
      'nip': nip,
    };
  }

  // Helper getters
  String get fullName => '$firstName $lastName'.trim();
}

class Shipping {
  final String firstName;
  final String lastName;
  final String phone;
  final String address;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.address,
  });

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
      'address': address,
    };
  }

  // Helper getters
  String get fullName => '$firstName $lastName'.trim();
}

// Removed OrderFeeLine - not needed for simplified structure

class Order {
  final int id;
  final String status;
  final DateTime dateCreated;
  final double total;
  final int customerId;
  final Billing billing;
  final List<OrderItem> lineItems;
  final String? taxFee;
  final String customerNote;
  final String number;

  Order({
    required this.id,
    required this.status,
    required this.dateCreated,
    required this.total,
    required this.customerId,
    required this.billing,
    required this.lineItems,
    this.taxFee,
    required this.customerNote,
    required this.number,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    // Parse date from string format "2025-09-10 02:36:51"
    DateTime parseDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return DateTime.now();
      try {
        return DateTime.parse(dateStr.replaceAll(' ', 'T') + 'Z');
      } catch (e) {
        return DateTime.now();
      }
    }
    
    return Order(
      id: json['id'] ?? 0,
      status: json['status'] ?? 'processing',
      dateCreated: parseDate(json['date_created']),
      total: double.tryParse(json['total']?.toString() ?? '0') ?? 0.0,
      customerId: json['customer_id'] ?? 0,
      billing: Billing.fromJson(json['billing'] ?? {}),
      lineItems: (json['line_items'] as List?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      taxFee: json['tax_fee']?.toString(),
      customerNote: json['customer_note'] ?? '',
      number: json['number'] ?? 'ORD-${json['id'] ?? 0}',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'status': status,
      'date_created': dateCreated.toIso8601String(),
      'total': total.toString(),
      'customer_id': customerId,
      'billing': billing.toJson(),
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'tax_fee': taxFee,
      'customer_note': customerNote,
      'number': number,
    };
  }

  // Helper getters
  String get customerName => billing.fullName;
  String get phone => billing.phone;
  String get address => billing.address;
  double get amount => total;
  String get orderId => number;
  DateTime get createdAt => dateCreated;
  List<OrderItem> get items => lineItems;
  OrderStatus get orderStatus => OrderStatus.fromString(status);
  
  // Tax fee helpers
  double get taxFeeAmount => double.tryParse(taxFee ?? '0') ?? 0.0;
  bool get hasTaxFee => taxFee != null && taxFee!.isNotEmpty && taxFeeAmount > 0;
}

enum OrderStatus {
  unpaid('Nieopłacone'),
  processing('Przetwarzanie'),
  paid('Zapłacone'),
  completed('Zakończone'),
  cancelled('Anulowane'),
  refunded('Zwrócone'),
  failed('Nieudane'),
  pending('Oczekujące'),
  onHold('Wstrzymane');

  const OrderStatus(this.displayName);
  final String displayName;

  static OrderStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'processing':
        return OrderStatus.processing;
      case 'completed':
        return OrderStatus.completed;
      case 'on-hold':
        return OrderStatus.onHold;
      case 'pending':
        return OrderStatus.pending;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'refunded':
        return OrderStatus.refunded;
      case 'failed':
        return OrderStatus.failed;
      default:
        return OrderStatus.unpaid;
    }
  }
}