import 'package:dio/dio.dart';
import 'package:store_manager/models/customer.dart';

class CustomerService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      headers: {
        'Authorization': basicAuth,
        'Content-Type': 'application/json',
      },
    ),
  );

  /// Search customers by name, email, or phone
  static Future<List<Customer>> searchCustomers({
    required String query,
    int perPage = 10,
  }) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final response = await dio.get(
        '/customers',
        queryParameters: {
          'search': query.trim(),
          'per_page': perPage,
          'orderby': 'name',
          'order': 'asc',
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search customers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to search customers: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get mock customers for testing (call this directly when you want to test with mock data)
  static Future<List<Customer>> getMockCustomers({required String query}) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    return _getMockCustomers(query);
  }

  /// Mock customers for testing
  static List<Customer> _getMockCustomers(String query) {
    final mockCustomers = [
      Customer(
        id: 1,
        firstName: 'Nguyễn',
        lastName: 'Văn An',
        email: 'nguyen.van.an@gmail.com',
        phone: '0901234567',
        company: 'Công ty TNHH ABC',
        nip: '0123456789',
        username: 'nguyenvanan',
        avatarUrl: 'https://ui-avatars.com/api/?name=Nguyen+Van+An&background=0D8ABC&color=fff',
        dateCreated: '2023-01-15T10:30:00',
        isPayingCustomer: true,
        billingAddress: CustomerAddress(
          firstName: 'Nguyễn',
          lastName: 'Văn An',
          company: 'Công ty TNHH ABC',
          address1: '123 Đường Lê Lợi',
          address2: '',
          city: 'TP.HCM',
          state: 'Hồ Chí Minh',
          postcode: '70000',
          country: 'VN',
          phone: '0901234567',
          email: 'nguyen.van.an@gmail.com',
        ),
        shippingAddress: CustomerAddress.empty(),
      ),
      Customer(
        id: 2,
        firstName: 'Trần',
        lastName: 'Thị Bình',
        email: 'tran.thi.binh@gmail.com',
        phone: '0987654321',
        company: 'Công ty XYZ',
        nip: '9876543210',
        username: 'tranthibinh',
        avatarUrl: 'https://ui-avatars.com/api/?name=Tran+Thi+Binh&background=FF6B6B&color=fff',
        dateCreated: '2023-02-20T14:15:00',
        isPayingCustomer: true,
        billingAddress: CustomerAddress(
          firstName: 'Trần',
          lastName: 'Thị Bình',
          company: 'Công ty XYZ',
          address1: '456 Đường Nguyễn Huệ',
          address2: 'Tầng 5',
          city: 'Hà Nội',
          state: 'Hà Nội',
          postcode: '10000',
          country: 'VN',
          phone: '0987654321',
          email: 'tran.thi.binh@gmail.com',
        ),
        shippingAddress: CustomerAddress.empty(),
      ),
      Customer(
        id: 3,
        firstName: 'Lê',
        lastName: 'Minh Cường',
        email: 'le.minh.cuong@gmail.com',
        phone: '0912345678',
        company: 'Doanh nghiệp tư nhân DEF',
        nip: '1122334455',
        username: 'leminhcuong',
        avatarUrl: 'https://ui-avatars.com/api/?name=Le+Minh+Cuong&background=4ECDC4&color=fff',
        dateCreated: '2023-03-10T09:45:00',
        isPayingCustomer: false,
        billingAddress: CustomerAddress(
          firstName: 'Lê',
          lastName: 'Minh Cường',
          company: 'Doanh nghiệp tư nhân DEF',
          address1: '789 Đường Trần Hưng Đạo',
          address2: '',
          city: 'Đà Nẵng',
          state: 'Đà Nẵng',
          postcode: '50000',
          country: 'VN',
          phone: '0912345678',
          email: 'le.minh.cuong@gmail.com',
        ),
        shippingAddress: CustomerAddress.empty(),
      ),
    ];

    // Filter mock customers based on query
    final lowerQuery = query.toLowerCase();
    return mockCustomers.where((customer) {
      return customer.fullName.toLowerCase().contains(lowerQuery) ||
             customer.email.toLowerCase().contains(lowerQuery) ||
             customer.phone.contains(lowerQuery) ||
             customer.company.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get customer by ID
  static Future<Customer?> getCustomerById(int customerId) async {
    try {
      final response = await dio.get(
        '/customers/$customerId',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(response.data);
      } else {
        throw Exception('Failed to get customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get customer: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      print('Error getting customer $customerId: $e');
      return null;
    }
  }

  /// Get recent customers (for quick access)
  static Future<List<Customer>> getRecentCustomers({int perPage = 20}) async {
    try {
      final response = await dio.get(
        '/customers',
        queryParameters: {
          'per_page': perPage,
          'orderby': 'date',
          'order': 'desc',
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get recent customers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get recent customers: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Get customers with pagination
  static Future<List<Customer>> getCustomers({int page = 1, int perPage = 20}) async {
    try {
      final response = await dio.get(
        '/customers',
        queryParameters: {
          'page': page,
          'per_page': perPage,
          'orderby': 'date',
          'order': 'desc',
        },
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Customer.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get customers: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to get customers: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Update customer
  static Future<Customer> updateCustomer(Map<String, dynamic> data) async {
    try {
      final customerId = data['id'];
      final response = await dio.put(
        '/customers/$customerId',
        data: data,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(response.data);
      } else {
        throw Exception('Failed to update customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to update customer: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Create customer
  static Future<Customer> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await dio.post(
        '/customers',
        data: data,
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      if (response.statusCode == 201) {
        return Customer.fromJson(response.data);
      } else {
        throw Exception('Failed to create customer: ${response.statusCode}');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to create customer: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }

  /// Delete customer
  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await dio.delete(
        '/customers/$customerId',
        queryParameters: {'force': true},
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception('Failed to delete customer: ${e.response?.statusCode} - ${e.response?.data}');
      } else {
        throw Exception('Network error: ${e.message}');
      }
    } catch (e) {
      throw Exception('Unexpected error: $e');
    }
  }
}