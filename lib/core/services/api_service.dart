import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'cache_service.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final CacheService? _cacheService;
  late final Dio _dio;

  ApiService({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    CacheService? cacheService,
  }) : defaultHeaders = defaultHeaders ?? {},
       _cacheService = cacheService {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        headers: this.defaultHeaders,
        responseType: ResponseType.plain,
      ),
    );
  }

  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
    bool useCache = true,
    Duration? cacheDuration,
    Duration? offlineCacheDuration,
  }) async {
    final uri = _buildUri(endpoint, queryParams);
    final cacheKey = uri.toString();

    if (useCache && _cacheService != null && cacheDuration != null) {
      final cached = _cacheService.get<dynamic>(
        cacheKey,
        validDuration: cacheDuration,
        deleteIfExpired: false,
      );
      if (cached != null) {
        final data = parser != null ? parser(cached) : cached as T;
        return ApiResponse.success(data, 200);
      }
    }

    try {
      final response = await _dio.getUri<String>(
        uri,
        options: Options(headers: headers),
      );

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final body = response.data;
        if (useCache && _cacheService != null && body != null) {
          await _cacheService.put(cacheKey, body);
        }

        final decoded = await compute(jsonDecode, body!);
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse.success(data, response.statusCode);
      }

      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse,
      );
    } catch (e) {
      if (useCache && _cacheService != null && offlineCacheDuration != null) {
        final staleCache = _cacheService.get<dynamic>(
          cacheKey,
          validDuration: offlineCacheDuration,
          deleteIfExpired: false,
        );

        if (staleCache != null) {
          final data = parser != null ? parser(staleCache) : staleCache as T;
          return ApiResponse.success(data, 200);
        }
      }

      if (e is DioException) {
        return ApiResponse.error('Erro de conexão: ${e.message}');
      }
      return ApiResponse.error('Erro: $e');
    }
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    T Function(dynamic)? parser,
  }) async {
    try {
      final response = await _dio.post<String>(endpoint, data: body);

      if (response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300) {
        final decoded = await compute(jsonDecode, response.data!);
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse.success(data, response.statusCode);
      }
      return ApiResponse.error(
        'Erro ${response.statusCode}',
        response.statusCode,
      );
    } on DioException catch (e) {
      return ApiResponse.error('Erro: ${e.message}');
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
