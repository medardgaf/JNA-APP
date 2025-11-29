import 'package:dio/dio.dart';

class Api {
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://k.jnatg.org/api', // adapte si nécessaire
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    ),
  );

  // exemple d'ajout d'intercepteur pour logging / auth token
  static void init(String? token) {
    dio.interceptors.clear();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (e, handler) => handler.next(e),
      ),
    );
  }
}
