import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Configured [Dio] wrapper shared across API calls.
///
/// The [baseUrl] is injected from configuration (`.env`, see
/// `API_BASE_URL`) instead of being hardcoded, and, when an
/// [authTokenProvider] is supplied, every request is authenticated with the
/// current Firebase user's ID token. Both values are optional so the client
/// works even before a backend or a signed-in user exists.
class DioClient {
  final Dio dio;

  DioClient(
    this.dio, {
    String baseUrl = '',
    Future<String?> Function()? authTokenProvider,
  }) {
    dio.options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final provider = authTokenProvider;
          if (provider != null) {
            try {
              final token = await provider();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            } catch (_) {
              // Requests must proceed even if auth token lookup fails; the
              // backend will reject unauthenticated calls on its own.
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // centralized error logging point
          return handler.next(error);
        },
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(requestBody: true, responseBody: true),
      );
    }
  }
}