class CustomerBilling {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String postcode;
  final String country;
  final String state;
  final String email;
  final String phone;

  CustomerBilling({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.country,
    required this.state,
    required this.email,
    required this.phone,
  });

  factory CustomerBilling.fromJson(Map<String, dynamic> json) {
    return CustomerBilling(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
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
      'postcode': postcode,
      'country': country,
      'state': state,
      'email': email,
      'phone': phone,
    };
  }
}

class CustomerShipping {
  final String firstName;
  final String lastName;
  final String company;
  final String address1;
  final String address2;
  final String city;
  final String postcode;
  final String country;
  final String state;
  final String phone;

  CustomerShipping({
    required this.firstName,
    required this.lastName,
    required this.company,
    required this.address1,
    required this.address2,
    required this.city,
    required this.postcode,
    required this.country,
    required this.state,
    required this.phone,
  });

  factory CustomerShipping.fromJson(Map<String, dynamic> json) {
    return CustomerShipping(
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      company: json['company'] ?? '',
      address1: json['address_1'] ?? '',
      address2: json['address_2'] ?? '',
      city: json['city'] ?? '',
      postcode: json['postcode'] ?? '',
      country: json['country'] ?? '',
      state: json['state'] ?? '',
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
      'postcode': postcode,
      'country': country,
      'state': state,
      'phone': phone,
    };
  }
}

class Customer {
  final int id;
  final String dateCreated;
  final String dateCreatedGmt;
  final String? dateModified;
  final String? dateModifiedGmt;
  final String email;
  final String firstName;
  final String lastName;
  final String role;
  final String username;
  final CustomerBilling billing;
  final CustomerShipping shipping;
  final bool isPayingCustomer;
  final String avatarUrl;
  final List<dynamic> metaData;

  Customer({
    required this.id,
    required this.dateCreated,
    required this.dateCreatedGmt,
    this.dateModified,
    this.dateModifiedGmt,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.role,
    required this.username,
    required this.billing,
    required this.shipping,
    required this.isPayingCustomer,
    required this.avatarUrl,
    required this.metaData,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      dateCreated: json['date_created'] ?? '',
      dateCreatedGmt: json['date_created_gmt'] ?? '',
      dateModified: json['date_modified'],
      dateModifiedGmt: json['date_modified_gmt'],
      email: json['email'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      role: json['role'] ?? '',
      username: json['username'] ?? '',
      billing: CustomerBilling.fromJson(json['billing'] ?? {}),
      shipping: CustomerShipping.fromJson(json['shipping'] ?? {}),
      isPayingCustomer: json['is_paying_customer'] ?? false,
      avatarUrl: json['avatar_url'] ?? '',
      metaData: json['meta_data'] ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date_created': dateCreated,
      'date_created_gmt': dateCreatedGmt,
      'date_modified': dateModified,
      'date_modified_gmt': dateModifiedGmt,
      'email': email,
      'first_name': firstName,
      'last_name': lastName,
      'role': role,
      'username': username,
      'billing': billing.toJson(),
      'shipping': shipping.toJson(),
      'is_paying_customer': isPayingCustomer,
      'avatar_url': avatarUrl,
      'meta_data': metaData,
    };
  }

  // Getter để lấy tên đầy đủ
  String get fullName {
    return '$firstName $lastName'.trim();
  }

  // Getter để lấy địa chỉ billing đầy đủ
  String get billingAddress {
    List<String> addressParts = [];
    if (billing.address1.isNotEmpty) addressParts.add(billing.address1);
    if (billing.address2.isNotEmpty) addressParts.add(billing.address2);
    if (billing.city.isNotEmpty) addressParts.add(billing.city);
    if (billing.postcode.isNotEmpty) addressParts.add(billing.postcode);
    if (billing.country.isNotEmpty) addressParts.add(billing.country);
    return addressParts.join(', ');
  }

  // Getter để lấy số điện thoại billing
  String get billingPhone {
    return billing.phone;
  }

  // Getter để lấy company billing
  String get billingCompany {
    return billing.company;
  }
}