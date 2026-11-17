import 'dart:convert';

import 'package:clean_arch_session/core/cache/cache_const.dart';
import 'package:clean_arch_session/core/cache/cache_helper.dart';
import 'package:clean_arch_session/core/networking/api_constants.dart';
import 'package:clean_arch_session/core/networking/api_service.dart';
import 'package:clean_arch_session/feature/auth/domain/entities/register_entity.dart';
import 'package:clean_arch_session/feature/auth/domain/repositories/auth_repo.dart';

class AuthRepoImpl implements AuthRepo {
  final ApiService _apiService;

  AuthRepoImpl(this._apiService);

  @override
  Future<String> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    await _saveSession(response.data);
    return _message(response.data, 'تم تسجيل الدخول بنجاح');
  }

  @override
  Future<String> register(RegisterEntity entity) async {
    final response = await _apiService.post(
      ApiConstants.register,
      data: {
        'name': entity.name,
        'email': entity.email,
        'password': entity.password,
        'password_confirmation': entity.passwordConfirmation,
      },
    );
    await _saveSession(response.data);
    return _message(response.data, 'تم إنشاء الحساب بنجاح');
  }

  Future<void> _saveSession(dynamic data) async {
    _apiService.clearResponseCache();
    final tokens = ApiService.findTokenPayload(data);
    final accessToken = tokens?['access_token'];
    if (accessToken is! String || accessToken.isEmpty) {
      throw StateError('لم يرجع الخادم access_token صالحاً.');
    }

    await CacheHelper.saveSecureData(
      key: CacheConstants.userToken,
      value: accessToken,
    );
    final refreshToken = tokens?['refresh_token'];
    if (refreshToken is String && refreshToken.isNotEmpty) {
      await CacheHelper.saveSecureData(
        key: CacheConstants.refreshToken,
        value: refreshToken,
      );
    }
    await CacheHelper.saveSecureData(
      key: CacheConstants.tokenUpdatedAt,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
    final userId = _findUserId(data) ?? _findUserIdInToken(accessToken);
    if (userId != null) {
      await CacheHelper.saveSecureData(
        key: CacheConstants.userId,
        value: userId.toString(),
      );
    }
  }

  String _message(dynamic data, String fallback) {
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    return fallback;
  }

  @override
  Future<String> logout() async {
    try {
      final response = await _apiService.post(ApiConstants.logout);
      return _message(response.data, 'تم تسجيل الخروج بنجاح');
    } finally {
      _apiService.clearResponseCache();
      await CacheHelper.deleteSecureData(key: CacheConstants.userToken);
      await CacheHelper.deleteSecureData(key: CacheConstants.refreshToken);
      await CacheHelper.deleteSecureData(key: CacheConstants.tokenUpdatedAt);
      await CacheHelper.deleteSecureData(key: CacheConstants.userId);
    }
  }

  dynamic _findUserId(dynamic value) {
    if (value is Map) {
      final user = value['user'];
      if (user is Map && user['id'] != null) return user['id'];
      for (final nested in value.values) {
        final result = _findUserId(nested);
        if (result != null) return result;
      }
    } else if (value is List) {
      for (final nested in value) {
        final result = _findUserId(nested);
        if (result != null) return result;
      }
    }
    return null;
  }

  dynamic _findUserIdInToken(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(utf8.decode(base64Url.decode(normalized)));
      if (payload is! Map) return null;
      return payload['user_id'] ?? payload['sub'] ?? payload['id'];
    } catch (_) {
      return null;
    }
  }
}
