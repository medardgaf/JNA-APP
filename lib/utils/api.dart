import 'package:dio/dio.dart';

class Api {
  static Dio dio = Dio(
    BaseOptions(
      baseUrl: "https://k.jnatg.org/api",
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {"Content-Type": "application/json"},
    ),
  );
}
