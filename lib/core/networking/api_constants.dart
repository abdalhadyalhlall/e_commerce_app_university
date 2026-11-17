import 'package:flutter/foundation.dart';

const _configuredApiUrl = String.fromEnvironment('API_BASE_URL');

class ApiConstants {
  static String get apiBaseUrl {
    if (_configuredApiUrl.isNotEmpty) {
      return _configuredApiUrl.endsWith('/')
          ? _configuredApiUrl
          : '$_configuredApiUrl/';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'https://tweak-recant-gout.ngrok-free.dev/';
      //'http://172.25.24.45:8000/';
       //'https://chasidy-judicatorial-william.ngrok-free.dev/';
    }
    return 'https://tweak-recant-gout.ngrok-free.dev/';
    //'http://127.0.0.1:8000/';
    //'https://chasidy-judicatorial-william.ngrok-free.dev/';
  }

  static const String v1 = 'v1';
  static const String login = 'api/E_commerce/$v1/auth/login';
  static const String register = 'api/E_commerce/$v1/auth/register';
  static const String refresh = 'api/E_commerce/$v1/auth/refresh';
  static const String logout = 'api/E_commerce/$v1/auth/logout';
  static const String categories = 'api/$v1/categories';
  static const String products = 'api/$v1/products';
  static const String cart = 'api/cart/$v1';
  static const String orders = 'api/orders/$v1';
}
