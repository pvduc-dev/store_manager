class Order {
  final int id;
  final String customerName;
  final double amount;
  final String currency;
  final int quantity;
  final OrderStatus status;
  final DateTime createdAt;

  Order({
    required this.id,
    required this.customerName,
    required this.amount,
    required this.currency,
    required this.quantity,
    required this.status,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      customerName: json['customer_name'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'zł',
      quantity: json['quantity'] ?? 0,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.unpaid,
      ),
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_name': customerName,
      'amount': amount,
      'currency': currency,
      'quantity': quantity,
      'status': status.name,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

enum OrderStatus {
  unpaid('không trả tiền'),
  processing('Đang thanh toán'),
  paid('Đã thanh toán');

  const OrderStatus(this.displayName);
  final String displayName;
}