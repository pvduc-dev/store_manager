
import 'package:store_manager/services/http_client.dart';

class AuthService {
  static Future<void> login(String username, String password) async {
    final httpClient = ApiService().getHttpClient();
    // Gọi API đăng nhập WooCommerce qua form /my-account/
    final response = await httpClient.post(
      '/my-account/',
      data: {
        'username': username,
        'password': password,
        'rememberme': 'forever',
        // Các trường này thường cần lấy động từ HTML, ở đây hardcode ví dụ:
        'woocommerce-login-nonce': '', // TODO: lấy nonce từ trang /my-account/
        '_wp_http_referer': '/my-account/',
        'login': 'Đăng nhập',
      },
    );

    if (response.statusCode == 200) {
      print('Login successful');
    } else {
      throw Exception('Failed to login');
    }
  }
}
