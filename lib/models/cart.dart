class Cart {
  final List<CartItem> items;
  final List<dynamic> coupons;
  final List<dynamic> fees;
  final CartTotals totals;
  final Address shippingAddress;
  final Address billingAddress;
  final bool needsPayment;
  final bool needsShipping;
  final List<String> paymentRequirements;
  final bool hasCalculatedShipping;
  final List<dynamic> shippingRates;
  final int itemsCount;
  final double itemsWeight;
  final List<dynamic> crossSells;
  final List<dynamic> errors;
  final List<String> paymentMethods;
  final Map<String, dynamic> extensions;

  Cart({
    required this.items,
    required this.coupons,
    required this.fees,
    required this.totals,
    required this.shippingAddress,
    required this.billingAddress,
    required this.needsPayment,
    required this.needsShipping,
    required this.paymentRequirements,
    required this.hasCalculatedShipping,
    required this.shippingRates,
    required this.itemsCount,
    required this.itemsWeight,
    required this.crossSells,
    required this.errors,
    required this.paymentMethods,
    required this.extensions,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      items: (json['items'] as List<dynamic>?)
          ?.map((item) => CartItem.fromJson(item))
          .toList() ?? [],
      coupons: json['coupons'] ?? [],
      fees: json['fees'] ?? [],
      totals: json['totals'] != null 
          ? CartTotals.fromJson(json['totals'])
          : CartTotals.empty(),
      shippingAddress: json['shipping_address'] != null
          ? Address.fromJson(json['shipping_address'])
          : Address.empty(),
      billingAddress: json['billing_address'] != null
          ? Address.fromJson(json['billing_address'])
          : Address.empty(),
      needsPayment: json['needs_payment'] ?? false,
      needsShipping: json['needs_shipping'] ?? false,
      paymentRequirements: List<String>.from(json['payment_requirements'] ?? []),
      hasCalculatedShipping: json['has_calculated_shipping'] ?? false,
      shippingRates: json['shipping_rates'] ?? [],
      itemsCount: json['items_count'] ?? 0,
      itemsWeight: (json['items_weight'] ?? 0).toDouble(),
      crossSells: json['cross_sells'] ?? [],
      errors: json['errors'] ?? [],
      paymentMethods: List<String>.from(json['payment_methods'] ?? []),
      extensions: json['extensions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'items': items.map((item) => item.toJson()).toList(),
      'coupons': coupons,
      'fees': fees,
      'totals': totals.toJson(),
      'shipping_address': shippingAddress.toJson(),
      'billing_address': billingAddress.toJson(),
      'needs_payment': needsPayment,
      'needs_shipping': needsShipping,
      'payment_requirements': paymentRequirements,
      'has_calculated_shipping': hasCalculatedShipping,
      'shipping_rates': shippingRates,
      'items_count': itemsCount,
      'items_weight': itemsWeight,
      'cross_sells': crossSells,
      'errors': errors,
      'payment_methods': paymentMethods,
      'extensions': extensions,
    };
  }
}

class CartItem {
  final String key;
  final int id;
  final String type;
  final int quantity;
  final QuantityLimits quantityLimits;
  final String name;
  final String shortDescription;
  final String description;
  final String sku;
  final int? lowStockRemaining;
  final bool backordersAllowed;
  final bool showBackorderBadge;
  final bool soldIndividually;
  final String permalink;
  final List<ProductImage> images;
  final List<dynamic> variation;
  final List<dynamic> itemData;
  final ItemPrices prices;
  final ItemTotals totals;
  final String catalogVisibility;
  final Map<String, dynamic> extensions;

  CartItem({
    required this.key,
    required this.id,
    required this.type,
    required this.quantity,
    required this.quantityLimits,
    required this.name,
    required this.shortDescription,
    required this.description,
    required this.sku,
    this.lowStockRemaining,
    required this.backordersAllowed,
    required this.showBackorderBadge,
    required this.soldIndividually,
    required this.permalink,
    required this.images,
    required this.variation,
    required this.itemData,
    required this.prices,
    required this.totals,
    required this.catalogVisibility,
    required this.extensions,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      key: json['key'] ?? '',
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? 0,
      quantityLimits: QuantityLimits.fromJson(json['quantity_limits']),
      name: json['name'] ?? '',
      shortDescription: json['short_description'] ?? '',
      description: json['description'] ?? '',
      sku: json['sku'] ?? '',
      lowStockRemaining: json['low_stock_remaining'],
      backordersAllowed: json['backorders_allowed'] ?? false,
      showBackorderBadge: json['show_backorder_badge'] ?? false,
      soldIndividually: json['sold_individually'] ?? false,
      permalink: json['permalink'] ?? '',
      images: (json['images'] as List<dynamic>)
          .map((image) => ProductImage.fromJson(image))
          .toList(),
      variation: json['variation'] ?? [],
      itemData: json['item_data'] ?? [],
      prices: ItemPrices.fromJson(json['prices']),
      totals: ItemTotals.fromJson(json['totals']),
      catalogVisibility: json['catalog_visibility'] ?? '',
      extensions: json['extensions'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'key': key,
      'id': id,
      'type': type,
      'quantity': quantity,
      'quantity_limits': quantityLimits.toJson(),
      'name': name,
      'short_description': shortDescription,
      'description': description,
      'sku': sku,
      'low_stock_remaining': lowStockRemaining,
      'backorders_allowed': backordersAllowed,
      'show_backorder_badge': showBackorderBadge,
      'sold_individually': soldIndividually,
      'permalink': permalink,
      'images': images.map((image) => image.toJson()).toList(),
      'variation': variation,
      'item_data': itemData,
      'prices': prices.toJson(),
      'totals': totals.toJson(),
      'catalog_visibility': catalogVisibility,
      'extensions': extensions,
    };
  }
}

class QuantityLimits {
  final int minimum;
  final int maximum;
  final int multipleOf;
  final bool editable;

  QuantityLimits({
    required this.minimum,
    required this.maximum,
    required this.multipleOf,
    required this.editable,
  });

  factory QuantityLimits.fromJson(Map<String, dynamic> json) {
    return QuantityLimits(
      minimum: json['minimum'] ?? 1,
      maximum: json['maximum'] ?? 9999,
      multipleOf: json['multiple_of'] ?? 1,
      editable: json['editable'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'minimum': minimum,
      'maximum': maximum,
      'multiple_of': multipleOf,
      'editable': editable,
    };
  }
}

class ProductImage {
  final int id;
  final String src;
  final String thumbnail;
  final String srcset;
  final String sizes;
  final String name;
  final String alt;

  ProductImage({
    required this.id,
    required this.src,
    required this.thumbnail,
    required this.srcset,
    required this.sizes,
    required this.name,
    required this.alt,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'] ?? 0,
      src: json['src'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      srcset: json['srcset'] ?? '',
      sizes: json['sizes'] ?? '',
      name: json['name'] ?? '',
      alt: json['alt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'src': src,
      'thumbnail': thumbnail,
      'srcset': srcset,
      'sizes': sizes,
      'name': name,
      'alt': alt,
    };
  }
}

class ItemPrices {
  final String price;
  final String regularPrice;
  final String salePrice;
  final String? priceRange;
  final String currencyCode;
  final String currencySymbol;
  final int currencyMinorUnit;
  final String currencyDecimalSeparator;
  final String currencyThousandSeparator;
  final String currencyPrefix;
  final String currencySuffix;
  final RawPrices rawPrices;

  ItemPrices({
    required this.price,
    required this.regularPrice,
    required this.salePrice,
    this.priceRange,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnit,
    required this.currencyDecimalSeparator,
    required this.currencyThousandSeparator,
    required this.currencyPrefix,
    required this.currencySuffix,
    required this.rawPrices,
  });

  factory ItemPrices.fromJson(Map<String, dynamic> json) {
    return ItemPrices(
      price: json['price'] ?? '',
      regularPrice: json['regular_price'] ?? '',
      salePrice: json['sale_price'] ?? '',
      priceRange: json['price_range'],
      currencyCode: json['currency_code'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      currencyMinorUnit: json['currency_minor_unit'] ?? 2,
      currencyDecimalSeparator: json['currency_decimal_separator'] ?? '.',
      currencyThousandSeparator: json['currency_thousand_separator'] ?? ',',
      currencyPrefix: json['currency_prefix'] ?? '',
      currencySuffix: json['currency_suffix'] ?? '',
      rawPrices: RawPrices.fromJson(json['raw_prices']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
      'price_range': priceRange,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_minor_unit': currencyMinorUnit,
      'currency_decimal_separator': currencyDecimalSeparator,
      'currency_thousand_separator': currencyThousandSeparator,
      'currency_prefix': currencyPrefix,
      'currency_suffix': currencySuffix,
      'raw_prices': rawPrices.toJson(),
    };
  }
}

class RawPrices {
  final int precision;
  final String price;
  final String regularPrice;
  final String salePrice;

  RawPrices({
    required this.precision,
    required this.price,
    required this.regularPrice,
    required this.salePrice,
  });

  factory RawPrices.fromJson(Map<String, dynamic> json) {
    return RawPrices(
      precision: json['precision'] ?? 6,
      price: json['price'] ?? '',
      regularPrice: json['regular_price'] ?? '',
      salePrice: json['sale_price'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'precision': precision,
      'price': price,
      'regular_price': regularPrice,
      'sale_price': salePrice,
    };
  }
}

class ItemTotals {
  final String lineSubtotal;
  final String lineSubtotalTax;
  final String lineTotal;
  final String lineTotalTax;
  final String currencyCode;
  final String currencySymbol;
  final int currencyMinorUnit;
  final String currencyDecimalSeparator;
  final String currencyThousandSeparator;
  final String currencyPrefix;
  final String currencySuffix;

  ItemTotals({
    required this.lineSubtotal,
    required this.lineSubtotalTax,
    required this.lineTotal,
    required this.lineTotalTax,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnit,
    required this.currencyDecimalSeparator,
    required this.currencyThousandSeparator,
    required this.currencyPrefix,
    required this.currencySuffix,
  });

  factory ItemTotals.fromJson(Map<String, dynamic> json) {
    return ItemTotals(
      lineSubtotal: json['line_subtotal'] ?? '',
      lineSubtotalTax: json['line_subtotal_tax'] ?? '',
      lineTotal: json['line_total'] ?? '',
      lineTotalTax: json['line_total_tax'] ?? '',
      currencyCode: json['currency_code'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      currencyMinorUnit: json['currency_minor_unit'] ?? 2,
      currencyDecimalSeparator: json['currency_decimal_separator'] ?? '.',
      currencyThousandSeparator: json['currency_thousand_separator'] ?? ',',
      currencyPrefix: json['currency_prefix'] ?? '',
      currencySuffix: json['currency_suffix'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'line_subtotal': lineSubtotal,
      'line_subtotal_tax': lineSubtotalTax,
      'line_total': lineTotal,
      'line_total_tax': lineTotalTax,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_minor_unit': currencyMinorUnit,
      'currency_decimal_separator': currencyDecimalSeparator,
      'currency_thousand_separator': currencyThousandSeparator,
      'currency_prefix': currencyPrefix,
      'currency_suffix': currencySuffix,
    };
  }
}

class CartTotals {
  final String totalItems;
  final String totalItemsTax;
  final String totalFees;
  final String totalFeesTax;
  final String totalDiscount;
  final String totalDiscountTax;
  final String? totalShipping;
  final String? totalShippingTax;
  final String totalPrice;
  final String totalTax;
  final List<dynamic> taxLines;
  final String currencyCode;
  final String currencySymbol;
  final int currencyMinorUnit;
  final String currencyDecimalSeparator;
  final String currencyThousandSeparator;
  final String currencyPrefix;
  final String currencySuffix;

  CartTotals({
    required this.totalItems,
    required this.totalItemsTax,
    required this.totalFees,
    required this.totalFeesTax,
    required this.totalDiscount,
    required this.totalDiscountTax,
    this.totalShipping,
    this.totalShippingTax,
    required this.totalPrice,
    required this.totalTax,
    required this.taxLines,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyMinorUnit,
    required this.currencyDecimalSeparator,
    required this.currencyThousandSeparator,
    required this.currencyPrefix,
    required this.currencySuffix,
  });

  factory CartTotals.empty() {
    return CartTotals(
      totalItems: '0',
      totalItemsTax: '0',
      totalFees: '0',
      totalFeesTax: '0',
      totalDiscount: '0',
      totalDiscountTax: '0',
      totalShipping: '0',
      totalShippingTax: '0',
      totalPrice: '0',
      totalTax: '0',
      taxLines: [],
      currencyCode: 'PLN',
      currencySymbol: 'zł',
      currencyMinorUnit: 2,
      currencyDecimalSeparator: '.',
      currencyThousandSeparator: ',',
      currencyPrefix: '',
      currencySuffix: ' zł',
    );
  }

  factory CartTotals.fromJson(Map<String, dynamic> json) {
    return CartTotals(
      totalItems: json['total_items'] ?? '',
      totalItemsTax: json['total_items_tax'] ?? '',
      totalFees: json['total_fees'] ?? '',
      totalFeesTax: json['total_fees_tax'] ?? '',
      totalDiscount: json['total_discount'] ?? '',
      totalDiscountTax: json['total_discount_tax'] ?? '',
      totalShipping: json['total_shipping'],
      totalShippingTax: json['total_shipping_tax'],
      totalPrice: json['total_price'] ?? '',
      totalTax: json['total_tax'] ?? '',
      taxLines: json['tax_lines'] ?? [],
      currencyCode: json['currency_code'] ?? '',
      currencySymbol: json['currency_symbol'] ?? '',
      currencyMinorUnit: json['currency_minor_unit'] ?? 2,
      currencyDecimalSeparator: json['currency_decimal_separator'] ?? '.',
      currencyThousandSeparator: json['currency_thousand_separator'] ?? ',',
      currencyPrefix: json['currency_prefix'] ?? '',
      currencySuffix: json['currency_suffix'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_items': totalItems,
      'total_items_tax': totalItemsTax,
      'total_fees': totalFees,
      'total_fees_tax': totalFeesTax,
      'total_discount': totalDiscount,
      'total_discount_tax': totalDiscountTax,
      'total_shipping': totalShipping,
      'total_shipping_tax': totalShippingTax,
      'total_price': totalPrice,
      'total_tax': totalTax,
      'tax_lines': taxLines,
      'currency_code': currencyCode,
      'currency_symbol': currencySymbol,
      'currency_minor_unit': currencyMinorUnit,
      'currency_decimal_separator': currencyDecimalSeparator,
      'currency_thousand_separator': currencyThousandSeparator,
      'currency_prefix': currencyPrefix,
      'currency_suffix': currencySuffix,
    };
  }
}

class Address {
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
  final String? email;

  Address({
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
    this.email,
  });

  factory Address.empty() {
    return Address(
      firstName: '',
      lastName: '',
      company: '',
      address1: '',
      address2: '',
      city: '',
      state: '',
      postcode: '',
      country: '',
      phone: '',
      email: '',
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
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
      email: json['email'],
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
      'email': email,
    };
  }
}
