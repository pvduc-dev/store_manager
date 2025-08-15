class OrderImage {
  final String id;
  final String src;

  OrderImage({
    required this.id,
    required this.src,
  });

  factory OrderImage.fromJson(Map<String, dynamic> json) {
    return OrderImage(
      id: json['id']?.toString() ?? '',
      src: json['src'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
    };
  }
}

class OrderItem {
  final int id;
  final String name;
  final int productId;
  final int variationId;
  final int quantity;
  final String taxClass;
  final String subtotal;
  final String subtotalTax;
  final String total;
  final String totalTax;
  final String sku;
  final double price;
  final OrderImage? image;
  final List<Map<String, dynamic>> metaData;

  OrderItem({
    required this.id,
    required this.name,
    required this.productId,
    required this.variationId,
    required this.quantity,
    required this.taxClass,
    required this.subtotal,
    required this.subtotalTax,
    required this.total,
    required this.totalTax,
    required this.sku,
    required this.price,
    this.image,
    required this.metaData,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      productId: json['product_id'] ?? 0,
      variationId: json['variation_id'] ?? 0,
      quantity: json['quantity'] ?? 0,
      taxClass: json['tax_class'] ?? '',
      subtotal: json['subtotal'] ?? '0.00',
      subtotalTax: json['subtotal_tax'] ?? '0.00',
      total: json['total'] ?? '0.00',
      totalTax: json['total_tax'] ?? '0.00',
      sku: json['sku'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      image: json['image'] != null ? OrderImage.fromJson(json['image']) : null,
      metaData: List<Map<String, dynamic>>.from(json['meta_data'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'product_id': productId,
      'variation_id': variationId,
      'quantity': quantity,
      'tax_class': taxClass,
      'subtotal': subtotal,
      'subtotal_tax': subtotalTax,
      'total': total,
      'total_tax': totalTax,
      'sku': sku,
      'price': price,
      'image': image?.toJson(),
      'meta_data': metaData,
    };
  }
}

class Billing {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String email;
  final String phone;

  Billing({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.email,
    required this.phone,
  });

  factory Billing.fromJson(Map<String, dynamic> json) {
    return Billing(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'email': email,
      'phone': phone,
    };
  }
}

class Shipping {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postcode;
  final String country;
  final String phone;

  Shipping({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postcode,
    required this.country,
    required this.phone,
  });

  factory Shipping.fromJson(Map<String, dynamic> json) {
    return Shipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      phone: json['phone'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'company': company,
      'address_1': address1,
      'address_2': address2,
      'city': city,
      'state': state,
      'postcode': postcode,
      'country': country,
      'phone': phone,
    };
  }
}

class OrderFeeLine {
  final int id;
  final String name;
  final String taxClass;
  final String taxStatus;
  final String total;
  final String totalTax;
  final List<Map<String, dynamic>> taxes;
  final List<Map<String, dynamic>> metaData;

  OrderFeeLine({
    required this.id,
    required this.name,
    required this.taxClass,
    required this.taxStatus,
    required this.total,
    required this.totalTax,
    required this.taxes,
    required this.metaData,
  });

  factory OrderFeeLine.fromJson(Map<String, dynamic> json) {
    return OrderFeeLine(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      taxClass: json['tax_class'] ?? '',
      taxStatus: json['tax_status'] ?? 'taxable',
      total: json['total'] ?? '0.00',
      totalTax: json['total_tax'] ?? '0.00',
      taxes: List<Map<String, dynamic>>.from(json['taxes'] ?? []),
      metaData: List<Map<String, dynamic>>.from(json['meta_data'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'tax_class': taxClass,
      'tax_status': taxStatus,
      'total': total,
      'total_tax': totalTax,
      'taxes': taxes,
      'meta_data': metaData,
    };
  }
}

class Order {
  final int id;
  final int parentId;
  final String status;
  final String currency;
  final String version;
  final bool pricesIncludeTax;
  final DateTime dateCreated;
  final DateTime dateModified;
  final String discountTotal;
  final String discountTax;
  final String shippingTotal;
  final String shippingTax;
  final String cartTax;
  final String total;
  final String totalTax;
  final int customerId;
  final String orderKey;
  final Billing billing;
  final Shipping shipping;
  final String paymentMethod;
  final String paymentMethodTitle;
  final String transactionId;
  final String customerIpAddress;
  final String customerUserAgent;
  final String createdVia;
  final String customerNote;
  final DateTime? dateCompleted;
  final DateTime? datePaid;
  final String cartHash;
  final String number;
  final List<Map<String, dynamic>> metaData;
  final List<OrderItem> lineItems;
  final List<OrderFeeLine> feeLines;
  final String currencySymbol;

  Order({
    required this.id,
    required this.parentId,
    required this.status,
    required this.currency,
    required this.version,
    required this.pricesIncludeTax,
    required this.dateCreated,
    required this.dateModified,
    required this.discountTotal,
    required this.discountTax,
    required this.shippingTotal,
    required this.shippingTax,
    required this.cartTax,
    required this.total,
    required this.totalTax,
    required this.customerId,
    required this.orderKey,
    required this.billing,
    required this.shipping,
    required this.paymentMethod,
    required this.paymentMethodTitle,
    required this.transactionId,
    required this.customerIpAddress,
    required this.customerUserAgent,
    required this.createdVia,
    required this.customerNote,
    this.dateCompleted,
    this.datePaid,
    required this.cartHash,
    required this.number,
    required this.metaData,
    required this.lineItems,
    required this.feeLines,
    required this.currencySymbol,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      parentId: json['parent_id'] ?? 0,
      status: json['status'] ?? '',
      currency: json['currency'] ?? '',
      version: json['version'] ?? '',
      pricesIncludeTax: json['prices_include_tax'] ?? false,
      dateCreated: DateTime.parse(json['date_created'] ?? DateTime.now().toIso8601String()),
      dateModified: DateTime.parse(json['date_modified'] ?? DateTime.now().toIso8601String()),
      discountTotal: json['discount_total'] ?? '0.00',
      discountTax: json['discount_tax'] ?? '0.00',
      shippingTotal: json['shipping_total'] ?? '0.00',
      shippingTax: json['shipping_tax'] ?? '0.00',
      cartTax: json['cart_tax'] ?? '0.00',
      total: json['total'] ?? '0.00',
      totalTax: json['total_tax'] ?? '0.00',
      customerId: json['customer_id'] ?? 0,
      orderKey: json['order_key'] ?? '',
      billing: Billing.fromJson(json['billing'] ?? {}),
      shipping: Shipping.fromJson(json['shipping'] ?? {}),
      paymentMethod: json['payment_method'] ?? '',
      paymentMethodTitle: json['payment_method_title'] ?? '',
      transactionId: json['transaction_id'] ?? '',
      customerIpAddress: json['customer_ip_address'] ?? '',
      customerUserAgent: json['customer_user_agent'] ?? '',
      createdVia: json['created_via'] ?? '',
      customerNote: json['customer_note'] ?? '',
      dateCompleted: json['date_completed'] != null ? DateTime.parse(json['date_completed']) : null,
      datePaid: json['date_paid'] != null ? DateTime.parse(json['date_paid']) : null,
      cartHash: json['cart_hash'] ?? '',
      number: json['number'] ?? '',
      metaData: List<Map<String, dynamic>>.from(json['meta_data'] ?? []),
      lineItems: (json['line_items'] as List?)
          ?.map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      feeLines: (json['fee_lines'] as List?)
          ?.map((item) => OrderFeeLine.fromJson(item as Map<String, dynamic>))
          .toList() ??
          [],
      currencySymbol: json['currency_symbol'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'status': status,
      'currency': currency,
      'version': version,
      'prices_include_tax': pricesIncludeTax,
      'date_created': dateCreated.toIso8601String(),
      'date_modified': dateModified.toIso8601String(),
      'discount_total': discountTotal,
      'discount_tax': discountTax,
      'shipping_total': shippingTotal,
      'shipping_tax': shippingTax,
      'cart_tax': cartTax,
      'total': total,
      'total_tax': totalTax,
      'customer_id': customerId,
      'order_key': orderKey,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'payment_method': paymentMethod,
      'payment_method_title': paymentMethodTitle,
      'transaction_id': transactionId,
      'customer_ip_address': customerIpAddress,
      'customer_user_agent': customerUserAgent,
      'created_via': createdVia,
      'customer_note': customerNote,
      'date_completed': dateCompleted?.toIso8601String(),
      'date_paid': datePaid?.toIso8601String(),
      'cart_hash': cartHash,
      'number': number,
      'meta_data': metaData,
      'line_items': lineItems.map((item) => item.toJson()).toList(),
      'fee_lines': feeLines.map((item) => item.toJson()).toList(),
      'currency_symbol': currencySymbol,
    };
  }

  // Getter methods để tương thích với code cũ
  String get customerName => '${billing.firstName} ${billing.lastName}'.trim();
  String get phone => billing.phone;
  String get address => '${billing.address1}, ${billing.city}'.trim();
  double get amount => double.tryParse(total) ?? 0.0;
  String get orderId => number;
  DateTime get createdAt => dateCreated;
  List<OrderItem> get items => lineItems;
  OrderStatus get orderStatus => OrderStatus.fromString(status);
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