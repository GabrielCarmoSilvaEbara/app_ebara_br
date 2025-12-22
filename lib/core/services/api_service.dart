import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';

class ApiService {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;
  final List<int> retryStatusCodes;
  final Box _cache = Hive.box('api_cache');

  ApiService({
    required this.baseUrl,
    Map<String, String>? defaultHeaders,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
    this.retryStatusCodes = const [408, 429, 500, 502, 503, 504],
  }) : defaultHeaders = defaultHeaders ?? {};

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

    ApiResponse<T>? cachedResponse;

    if (useCache && _cache.containsKey(cacheKey)) {
      final cachedEntry = Map<String, dynamic>.from(_cache.get(cacheKey));
      final int savedAt = cachedEntry['timestamp'];
      final String rawData = cachedEntry['data'];

      final now = DateTime.now().millisecondsSinceEpoch;
      final ttl =
          cacheDuration?.inMilliseconds ??
          const Duration(hours: 24).inMilliseconds;

      try {
        final decoded = json.decode(rawData);
        final data = parser != null ? parser(decoded) : decoded as T;
        cachedResponse = ApiResponse.success(data, 200);

        if (now - savedAt < ttl) {
          return cachedResponse;
        }
      } catch (_) {
        _cache.delete(cacheKey);
      }
    }

    if (cachedResponse != null) {
      _request<T>(
        method: 'GET',
        endpoint: endpoint,
        queryParams: queryParams,
        headers: headers,
        parser: parser,
      );
      return cachedResponse;
    }

    return _request<T>(
      method: 'GET',
      endpoint: endpoint,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    return _request<T>(
      method: 'POST',
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
      headers: headers,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> _request<T>({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
    T Function(dynamic)? parser,
  }) async {
    int attempt = 0;
    final uri = _buildUri(endpoint, queryParams);
    final cacheKey = uri.toString();

    while (attempt <= maxRetries) {
      try {
        final mergedHeaders = {...defaultHeaders, ...?headers};

        final response = await _executeRequest(
          method: method,
          uri: uri,
          body: body,
          headers: mergedHeaders,
        ).timeout(timeout);

        if (_shouldRetry(response.statusCode, attempt)) {
          attempt++;
          await _waitBeforeRetry(attempt);
          continue;
        }

        final apiResponse = _handleResponse<T>(response, parser);

        if (method == 'GET' && apiResponse.isSuccess) {
          final cacheData = {
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'data': response.body,
          };
          await _cache.put(cacheKey, cacheData);
        }

        return apiResponse;
      } on http.ClientException catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          await _waitBeforeRetry(attempt);
          continue;
        }
        return ApiResponse.error('Erro de conexão: ${e.message}');
      } catch (e) {
        if (attempt < maxRetries) {
          attempt++;
          await _waitBeforeRetry(attempt);
          continue;
        }
        return ApiResponse.error('Erro inesperado: $e');
      }
    }
    return ApiResponse.error('Falha após $maxRetries tentativas');
  }

  bool _shouldRetry(int statusCode, int currentAttempt) {
    return currentAttempt < maxRetries && retryStatusCodes.contains(statusCode);
  }

  Future<void> _waitBeforeRetry(int attempt) async {
    final delay = retryDelay * (1 << (attempt - 1));
    await Future.delayed(delay);
  }

  Uri _buildUri(String endpoint, Map<String, dynamic>? queryParams) {
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    final url = '$baseUrl$path';
    if (queryParams != null && queryParams.isNotEmpty) {
      final cleanParams = queryParams.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      return Uri.parse(url).replace(queryParameters: cleanParams);
    }
    return Uri.parse(url);
  }

  Future<http.Response> _executeRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    required Map<String, String> headers,
  }) {
    switch (method) {
      case 'GET':
        return http.get(uri, headers: headers);
      case 'POST':
        return http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'PUT':
        return http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      case 'DELETE':
        return http.delete(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
      default:
        throw UnsupportedError('Método não suportado');
    }
  }

  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic)? parser,
  ) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final decoded = json.decode(response.body);
        final data = parser != null ? parser(decoded) : decoded as T;
        return ApiResponse.success(data, response.statusCode);
      } catch (e) {
        return ApiResponse.error(
          'Erro ao decodificar: $e',
          response.statusCode,
        );
      }
    }
    return ApiResponse.error(
      'Erro ${response.statusCode}',
      response.statusCode,
    );
  }

  Future<void> clearCache() async => await _cache.clear();
}

class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool isSuccess;

  ApiResponse._({
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
