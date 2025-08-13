import 'package:dio/dio.dart';
import '../models/customer.dart';

class CustomerService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/v3';
  static const String basicAuth =
      'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q';

  static Future<List<Customer>> getCustomers({
    int page = 1, 
    int perPage = 20,
    String? search,
  }) async {
    try {
      // Build URL with optional search parameter
      String url = '$baseUrl/customers?per_page=$perPage&page=$page&orderby=registered_date&order=desc';
      if (search != null && search.isNotEmpty) {
        url += '&search=$search';
      }
      
      final response = await Dio().get(
        url,
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data
            .map((json) => Customer.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        print('Error fetching customers: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception while fetching customers: $e');
      return [];
    }
  }

  static Future<Customer?> getCustomerById(int customerId) async {
    try {
      final response = await Dio().get(
        '$baseUrl/customers/$customerId',
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(response.data);
      } else {
        print('Error fetching customer: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while fetching customer: $e');
      return null;
    }
  }

  static Future<Customer?> createCustomer(Map<String, dynamic> data) async {
    try {
      final response = await Dio().post(
        '$baseUrl/customers',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 201) {
        return Customer.fromJson(response.data);
      } else {
        print('Error creating customer: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while creating customer: $e');
      return null;
    }
  }

  static Future<Customer?> updateCustomer(Map<String, dynamic> data) async {
    try {
      final response = await Dio().put(
        '$baseUrl/customers/${data['id']}',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/json',
          },
        ),
        data: data,
      );

      if (response.statusCode == 200) {
        return Customer.fromJson(response.data);
      } else {
        print('Error updating customer: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception while updating customer: $e');
      return null;
    }
  }

  static Future<bool> deleteCustomer(int customerId) async {
    try {
      final response = await Dio().delete(
        '$baseUrl/customers/$customerId',
        options: Options(headers: {'Authorization': basicAuth}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        print('Error deleting customer: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('Exception while deleting customer: $e');
      return false;
    }
  }
}