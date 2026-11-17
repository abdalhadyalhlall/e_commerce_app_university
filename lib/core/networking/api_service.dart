import 'package:clean_arch_session/core/cache/cache_const.dart';
import 'package:clean_arch_session/core/cache/cache_helper.dart';
import 'package:clean_arch_session/core/networking/api_constants.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

const _authorizationHeader = 'Author' 'ization';

class ApiService {
  final Dio dio;
  final Map<String, String> _entityTags = {};
  final Map<String, Response<dynamic>> _cachedResponses = {};
  Future<void>? _refreshInProgress;

  ApiService(this.dio) {
    dio.options.baseUrl = ApiConstants.apiBaseUrl;
    dio.options.connectTimeout = const Duration(seconds: 20);
    dio.options.receiveTimeout = const Duration(seconds: 20);
    dio.options.headers = {'Accept': 'application/json'};
    dio.interceptors.add(InterceptorsWrapper(onRequest: _addToken));
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: false,
          requestBody: true,
          responseBody: true,
          responseHeader: false,
          error: true,
          compact: true,
          maxWidth: 90,
        ),
      );
    }
  }

  Future<void> _addToken(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (options.extra['skipTokenRefresh'] == true) {
        handler.next(options);
        return;
      }

      var token = await CacheHelper.getSecureData(
        key: CacheConstants.userToken,
      );
      if (token != null && _requiresAuthentication(options.path)) {
        await _refreshIfDue();
        token = await CacheHelper.getSecureData(key: CacheConstants.userToken);
      }
      if (token != null) {
        options.headers[_authorizationHeader] = ['Bearer', token].join(' ');
      }
      handler.next(options);
    } catch (error) {
      handler.reject(
        error is DioException
            ? error
            : DioException(requestOptions: options, error: error),
      );
    }
  }

  bool _requiresAuthentication(String path) {
    return path != ApiConstants.login &&
        path != ApiConstants.register &&
        path != ApiConstants.categories &&
        path != ApiConstants.products &&
        path != ApiConstants.refresh;
  }

  Future<void> _refreshIfDue() async {
    final lastUpdated = await CacheHelper.getSecureData(
      key: CacheConstants.tokenUpdatedAt,
    );
    final updatedAt = int.tryParse(lastUpdated ?? '');
    if (updatedAt == null ||
        DateTime.now().millisecondsSinceEpoch - updatedAt <
            const Duration(minutes: 10).inMilliseconds) {
      return;
    }

    final currentRefresh = _refreshInProgress;
    if (currentRefresh != null) {
      await currentRefresh;
      return;
    }

    final refresh = _refreshAccessToken();
    _refreshInProgress = refresh;
    try {
      await refresh;
    } finally {
      _refreshInProgress = null;
    }
  }

  Future<void> _refreshAccessToken() async {
    final refreshToken = await CacheHelper.getSecureData(
      key: CacheConstants.refreshToken,
    );
    if (refreshToken == null || refreshToken.isEmpty) {
      throw StateError('The session expired. Please sign in again.');
    }

    final response = await dio.post<dynamic>(
      ApiConstants.refresh,
      options: Options(
        headers: {
          _authorizationHeader: ['Bearer', refreshToken].join(' '),
        },
        extra: const {'skipTokenRefresh': true},
      ),
    );
    final tokens = _findTokenPayload(response.data);
    final accessToken = tokens?['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw StateError('The refresh response did not contain an access token.');
    }

    final nextRefreshToken = tokens?['refresh_token'];
    await CacheHelper.saveSecureData(
      key: CacheConstants.userToken,
      value: accessToken,
    );
    if (nextRefreshToken is String && nextRefreshToken.isNotEmpty) {
      await CacheHelper.saveSecureData(
        key: CacheConstants.refreshToken,
        value: nextRefreshToken,
      );
    }
    await CacheHelper.saveSecureData(
      key: CacheConstants.tokenUpdatedAt,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  static Map<String, dynamic>? findTokenPayload(dynamic value) =>
      _findTokenPayload(value);

  static Map<String, dynamic>? _findTokenPayload(dynamic value) {
    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      if (map['access_token'] is String) return map;
      for (final nested in map.values) {
        final result = _findTokenPayload(nested);
        if (result != null) return result;
      }
    } else if (value is List) {
      for (final nested in value) {
        final result = _findTokenPayload(nested);
        if (result != null) return result;
      }
    }
    return null;
  }

  Future<Response<dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
  }) async {
    final token = await CacheHelper.getSecureData(
      key: CacheConstants.userToken,
    );
    final cacheKey = _getCacheKey(endpoint, queryParameters, token);
    final etag = _entityTags[cacheKey];
    final response = await dio.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: Options(
        validateStatus: (status) =>
            status != null && (status == 304 || status >= 200 && status < 300),
        headers: etag == null ? null : {'If-None-Match': etag},
      ),
    );

    if (response.statusCode == 304) {
      final cached = _cachedResponses[cacheKey];
      if (cached == null) {
        throw StateError('The server returned 304 without a cached response.');
      }
      return Response<dynamic>(
        requestOptions: response.requestOptions,
        data: cached.data,
        headers: response.headers,
        statusCode: response.statusCode,
      );
    }

    final responseEtag = response.headers.value('etag');
    if (responseEtag != null) {
      _entityTags[cacheKey] = responseEtag;
      _cachedResponses[cacheKey] = response;
    } else {
      _entityTags.remove(cacheKey);
      _cachedResponses.remove(cacheKey);
    }
    return response;
  }

  String _getCacheKey(
    String endpoint,
    Map<String, dynamic>? queryParameters,
    String? token,
  ) {
    final uri = Uri.parse('${dio.options.baseUrl}$endpoint');
    final requestUri = uri.replace(
      queryParameters: queryParameters?.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
    );
    return '$requestUri\n${token ?? ''}';
  }

  void clearResponseCache() {
    _entityTags.clear();
    _cachedResponses.clear();
  }

  void invalidateCache(String endpoint) {
    final requestPrefix = '${dio.options.baseUrl}$endpoint';
    _entityTags.removeWhere((key, _) => key.startsWith(requestPrefix));
    _cachedResponses.removeWhere((key, _) => key.startsWith(requestPrefix));
  }

  Future<Response<dynamic>> post(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.post<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> put(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.put<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }

  Future<Response<dynamic>> delete(
    String endpoint, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) {
    return dio.delete<dynamic>(
      endpoint,
      data: data,
      queryParameters: queryParameters,
    );
  }
}
