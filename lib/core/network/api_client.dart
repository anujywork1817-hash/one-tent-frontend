import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class AppDio {
  static final AppDio _instance = AppDio._internal();
  factory AppDio() => _instance;

  final Dio dio;
  final _storage = const FlutterSecureStorage();

  AppDio._internal()
      : dio = Dio(BaseOptions(
          baseUrl: AppConstants.baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {'Content-Type': 'application/json'},
        )) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
final token = await _storage.read(key: AppConstants.tokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        print('API ERROR: ${error.requestOptions.method} '
            '${error.requestOptions.uri}');
        print('API ERROR status: ${error.response?.statusCode}');
        print('API ERROR body: ${error.response?.data}');
        print('API ERROR message: ${error.message}');
        handler.next(error);
      },
    ));

    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

 Future<void> saveToken(String token) async {
  await _storage.write(key: AppConstants.tokenKey, value: token);
}

Future<void> clearToken() async {
  await _storage.delete(key: AppConstants.tokenKey);
}
}