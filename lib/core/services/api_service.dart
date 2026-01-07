import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'cache_service.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final CacheService? _cacheService;
  final http.Client _client = http.Client();

  ApiService({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    CacheService? cacheService,
  }) : defaultHeaders = defaultHeaders ?? {},
       _cacheService = cacheService;

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool useCache = true,
    Duration? cacheDuration,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final cacheKey = uri.toString();

    if (useCache && _cacheService != null) {
      final cached = _cacheService.get<dynamic>(
        cacheKey,
        validDuration: cacheDuration,
      );
      if (cached != null) {
        final data = parser != null ? parser(cached) : cached as T;
        return ApiResponse.success(data, 200);
      }
    }

    try {
      final response = await _client
          .get(uri, headers: {...defaultHeaders, ...?headers})
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final body = response.body;
        if (useCache && _cacheService != null) {
          await _cacheService.put(cacheKey, body);
        }

        final decoded = await compute(jsonDecode, body);
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse.success(data, response.statusCode);
      }

      return ApiResponse.error(
        'Erro ${response.statusCode}: ${response.reasonPhrase}',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Erro de conexão: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
  }) async {
    try {
      final uri = _buildUri(endpoint, null);
      final response = await _client
          .post(
            uri,
            headers: defaultHeaders,
            body: body != null ? jsonEncode(body) : null,
          )
          .timeout(timeout);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = await compute(jsonDecode, response.body);
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse.success(data, response.statusCode);
      }
      return ApiResponse.error(
        'Erro ${response.statusCode}',
        response.statusCode,
      );
    } catch (e) {
      return ApiResponse.error('Erro: $e');
    }
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map((k, v) => MapEntry(k, v.toString()));
      return Uri.parse(url).replace(queryParameters: cleanParams);
    }
    return Uri.parse(url);
  }
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  const ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.isSuccess,
  });

  factory ApiResponse.success(T data, [int? statusCode]) =>
      ApiResponse._(data: data, statusCode: statusCode, isSuccess: true);

  factory ApiResponse.error(String error, [int? statusCode]) =>
      ApiResponse._(error: error, statusCode: statusCode, isSuccess: false);

  T? get dataOrNull => isSuccess ? data : null;
}
