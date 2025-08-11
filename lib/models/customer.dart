class Customer {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final String company;
  final String nip;
  final String username;
  final String avatarUrl;
  final String dateCreated;
  final bool isPayingCustomer;
  final CustomerAddress billingAddress;
  final CustomerAddress shippingAddress;

  Customer({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.company,
    required this.nip,
    required this.username,
    required this.avatarUrl,
    required this.dateCreated,
    required this.isPayingCustomer,
    required this.billingAddress,
    required this.shippingAddress,
  });

  String get fullName => '$firstName $lastName'.trim();
  
  // Backward compatibility getters
  CustomerAddress get billing => billingAddress;
  String get billingPhone => billingAddress.phone.isNotEmpty ? billingAddress.phone : phone;
  String get billingCompany => billingAddress.company.isNotEmpty ? billingAddress.company : company;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      company: json['company'] ?? '',
      nip: json['nip'] ?? '',
      username: json['username'] ?? '',
      avatarUrl: json['avatar_url'] ?? '',
      dateCreated: json['date_created'] ?? '',
      isPayingCustomer: json['is_paying_customer'] ?? false,
      billingAddress: json['billing'] != null 
          ? CustomerAddress.fromJson(json['billing'])
          : CustomerAddress.empty(),
      shippingAddress: json['shipping'] != null 
          ? CustomerAddress.fromJson(json['shipping'])
          : CustomerAddress.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'phone': phone,
      'company': company,
      'nip': nip,
      'username': username,
      'avatar_url': avatarUrl,
      'date_created': dateCreated,
      'is_paying_customer': isPayingCustomer,
      'billing': billingAddress.toJson(),
      'shipping': shippingAddress.toJson(),
    };
  }
}

class CustomerAddress {
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
  final String email;

  CustomerAddress({
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
    required this.email,
  });

  String get fullAddress {
    final parts = [address1, address2, city, state, postcode, country]
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  bool get isNotEmpty {
    return firstName.isNotEmpty ||
           lastName.isNotEmpty ||
           company.isNotEmpty ||
           address1.isNotEmpty ||
           address2.isNotEmpty ||
           city.isNotEmpty ||
           state.isNotEmpty ||
           postcode.isNotEmpty ||
           country.isNotEmpty ||
           phone.isNotEmpty ||
           email.isNotEmpty;
  }

  factory CustomerAddress.empty() {
    return CustomerAddress(
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

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
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
      email: json['email'] ?? '',
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