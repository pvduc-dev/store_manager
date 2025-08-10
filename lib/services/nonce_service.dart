import 'package:dio/dio.dart';

class NonceService {
  static const String baseUrl = 'https://kochamtoys.pl/wp-json/wc/store/v1';
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

  static String? _cachedNonce;
  static DateTime? _nonceExpiry;

  /// Lấy nonce header từ WooCommerce API
  /// Nonce được cache trong 30 phút để tránh gọi API quá nhiều
  static Future<String> getNonce() async {
    // Kiểm tra cache (giảm thời gian cache xuống 30 phút)
    if (_cachedNonce != null && 
        _nonceExpiry != null && 
        DateTime.now().isBefore(_nonceExpiry!)) {
      return _cachedNonce!;
    }

    try {
      // Gọi API để lấy nonce mới từ endpoint đặc biệt
      final response = await dio.get('/cart');
      
      // Kiểm tra nonce trong response headers theo thứ tự ưu tiên
      String? nonce = response.headers.value('X-WC-Store-API-Nonce') ??
                     response.headers.value('Nonce') ??
                     response.headers.value('x-wc-store-api-nonce');

      // Nếu không có trong headers, thử lấy từ response data
      if (nonce == null || nonce.isEmpty) {
        nonce = response.data?['nonce'] ?? 
                response.data?['X-WC-Store-API-Nonce'];
      }

      if (nonce != null && nonce.isNotEmpty) {
        _cachedNonce = nonce;
        // Giảm thời gian cache xuống 30 phút vì nonce có thể expire
        _nonceExpiry = DateTime.now().add(const Duration(minutes: 30));
        print('Got nonce: ${nonce.substring(0, 8)}...');
        return nonce;
      } else {
        print('No nonce found in response headers or data');
        // Thử tạo nonce bằng cách gọi endpoint khác
        return await _tryGetNonceFromAlternativeEndpoint();
      }
    } on DioException catch (e) {
      print('Error getting nonce: ${e.message}');
      if (e.response != null) {
        print('Response status: ${e.response?.statusCode}');
        print('Response headers: ${e.response?.headers}');
      }
      return '';
    } catch (e) {
      print('Unexpected error getting nonce: $e');
      return '';
    }
  }

  /// Thử lấy nonce từ endpoint khác
  static Future<String> _tryGetNonceFromAlternativeEndpoint() async {
    try {
      // Thử gọi endpoint khác có thể trả về nonce
      final response = await dio.get('/products', queryParameters: {'per_page': 1});
      
      String? nonce = response.headers.value('X-WC-Store-API-Nonce') ??
                     response.headers.value('Nonce') ??
                     response.headers.value('x-wc-store-api-nonce');

      if (nonce != null && nonce.isNotEmpty) {
        _cachedNonce = nonce;
        _nonceExpiry = DateTime.now().add(const Duration(minutes: 30));
        print('Got nonce from alternative endpoint: ${nonce.substring(0, 8)}...');
        return nonce;
      }
      
      print('No nonce found from alternative endpoint either');
      return '';
    } catch (e) {
      print('Error getting nonce from alternative endpoint: $e');
      return '';
    }
  }

  /// Xóa cache nonce (dùng khi logout hoặc cần refresh)
  static void clearNonce() {
    _cachedNonce = null;
    _nonceExpiry = null;
  }

  /// Cập nhật nonce từ response (được gọi từ CartService)
  static void updateNonce(String newNonce) {
    if (newNonce.isNotEmpty) {
      _cachedNonce = newNonce;
      _nonceExpiry = DateTime.now().add(const Duration(minutes: 30));
      print('Nonce updated: ${newNonce.substring(0, 8)}...');
    }
  }

  /// Kiểm tra xem nonce có hợp lệ không
  static bool isNonceValid() {
    return _cachedNonce != null && 
           _nonceExpiry != null && 
           DateTime.now().isBefore(_nonceExpiry!);
  }
}
