import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  late Dio _dio;
  late CookieJar _cookieJar;

  factory ApiService() {
    return _instance;
  }

  ApiService._internal() {
    // Khởi tạo Dio
    _dio = Dio(BaseOptions(
      baseUrl: 'https://kochamtoys.pl',
      headers: {
        'Authorization': 'Basic cGhhcHZuOk1MNmcgSUx6MCBNYm45IEp3Q0MgcUNwSiB2ZU9q',
        'Content-Type': 'application/json',
      },
    ));

    // Khởi tạo CookieJar để lưu trữ cookie
    _cookieJar = CookieJar();

    // Thêm CookieManager vào Dio
    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  Dio get dio => _dio;

  Dio getHttpClient() {
    return _dio;
  }

  // Lấy danh sách cookie
  Future<List<Cookie>> getCookies(Uri uri) async {
    return await _cookieJar.loadForRequest(uri);
  }

  // Xóa cookie
  void clearCookies() {
    _cookieJar.deleteAll();
  }
}