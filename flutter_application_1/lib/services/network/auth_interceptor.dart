import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _storage;

  AuthInterceptor(this._storage);

 @override
Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
  final token = await _storage.read(key: 'jwt_token');
  
  if (token != null) {
    // 🎯 FIX : Nettoyage radical avant envoi
    final cleanToken = token.trim().replaceAll(RegExp(r'\s+'), '');
    options.headers['Authorization'] = 'Bearer $cleanToken';
  }
  return handler.next(options);
}
}