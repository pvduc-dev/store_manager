class Customer {
  final int id;
  final String firstName;
  final String email;
  final String nip;
  final String phone;
  final String address;
  final int orderCount;
  final DateTime? registeredDate;

  Customer({
    required this.id,
    required this.firstName,
    required this.email,
    required this.nip,
    required this.phone,
    required this.address,
    required this.orderCount,
    this.registeredDate,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    DateTime? registeredDate;
    if (json['registered_date'] != null) {
      try {
        registeredDate = DateTime.parse(json['registered_date']);
      } catch (e) {
        print('Error parsing registered_date: $e');
      }
    }

    return Customer(
      id: json['id'] ?? 0,
      firstName: json['first_name'] ?? '',
      email: json['email'] ?? '',
      nip: json['nip'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      orderCount: json['order_count'] ?? 0,
      registeredDate: registeredDate,
    );
  }

  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'first_name': firstName,
      'email': email,
      'nip': nip,
      'phone': phone,
      'address': address,
      'order_count': orderCount,
    };
    
    if (registeredDate != null) {
      json['registered_date'] = registeredDate!.toIso8601String();
    }
    
    return json;
  }

  // Getter để lấy tên đầy đủ
  String get fullName {
    return firstName.trim();
  }

  // Getter để lấy ngày đăng ký đã format
  String get formattedRegisteredDate {
    if (registeredDate == null) return 'Brak informacji';
    
    final date = registeredDate!;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // Check nếu là khách hàng mới (đăng ký trong 30 ngày qua)
  bool get isNewCustomer {
    if (registeredDate == null) return false;
    
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return registeredDate!.isAfter(thirtyDaysAgo);
  }
}