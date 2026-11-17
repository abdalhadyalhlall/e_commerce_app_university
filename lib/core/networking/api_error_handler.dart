import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiErrorHandler {
  static const String _defaultMessage =
      'Something went wrong, please try again';

  static String getMessage(Object error) {
    if (error is! DioException) {
      debugPrint('Unexpected error: $error');
      return _defaultMessage;
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out, please try again';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      case DioExceptionType.badResponse:
        return _getServerMessage(error.response?.data);
      default:
        return _defaultMessage;
    }
  }

  static String _getServerMessage(dynamic data) {
    if (data is! Map<String, dynamic>) return _defaultMessage;

    final message = data['message'];
    if (message is String) return message;
    if (message is Map<String, dynamic>) {
      return message.values
          .expand((fieldErrors) => fieldErrors as List)
          .join('\n');
    }
    return _defaultMessage;
  }
}
