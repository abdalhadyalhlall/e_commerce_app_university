import 'dart:async';
import 'dart:convert';

import 'package:clean_arch_session/core/cache/cache_const.dart';
import 'package:clean_arch_session/core/cache/cache_helper.dart';
import 'package:clean_arch_session/core/networking/api_service.dart';
import 'package:clean_arch_session/feature/store/domain/entities/store_entities.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class OrderRealtimeEvent {
  final String action;
  final StoreOrder order;

  const OrderRealtimeEvent({required this.action, required this.order});
}

class OrderRealtimeService {
  static const _eventName = 'order.updated';
  static const _configuredHost = String.fromEnvironment('REVERB_HOST');
  static const _configuredPort = int.fromEnvironment(
    'REVERB_PORT',
    defaultValue: 443,
  );
  static const _useTls = bool.fromEnvironment(
    'REVERB_USE_TLS',
    defaultValue: true,
  );
  static const _appKey = String.fromEnvironment(
    'REVERB_APP_KEY',
    defaultValue: 'abcdef123456789',
  );

  final ApiService _api;
  final _events = StreamController<OrderRealtimeEvent>.broadcast();
  final _errors = StreamController<String>.broadcast();
  WebSocketChannel? _socket;
  Timer? _reconnectTimer;
  bool _closed = false;
  bool _subscribed = false;

  OrderRealtimeService(this._api);

  Stream<OrderRealtimeEvent> get events => _events.stream;
  Stream<String> get errors => _errors.stream;

  String get host {
    if (_configuredHost.isNotEmpty) return _configuredHost;
    return //'tweak-recant-gout.ngrok-free.dev';
             'cute-radios-nail.loca.lt';
  }

  Future<void> connect() async {
    if (_closed || _socket != null) return;
    final userId = await _ensureUserId();
    if (userId == null || userId.isEmpty) {
      _reportError('تعذر تشغيل تحديث الطلبات: رقم المستخدم غير محفوظ.');
      _scheduleReconnect();
      return;
    }

    final uri = Uri(
      scheme: _useTls ? 'wss' : 'ws',
      host: host,
      port: _configuredPort,
      path: '/app/$_appKey',
      queryParameters: const {
        'protocol': '7',
        'client': 'flutter',
        'version': '1.0',
        'flash': 'false',
      },
    );
    try {
      final socket = WebSocketChannel.connect(uri);
      _socket = socket;
      _subscribed = false;
      socket.stream.listen(
        _handleMessage,
        onError: (Object error, StackTrace stackTrace) {
          _reportError('تعذر الاتصال بالتحديثات الفورية: $error');
          _scheduleReconnect();
        },
        onDone: _scheduleReconnect,
        cancelOnError: true,
      );
      await socket.ready;
    } catch (error) {
      _socket = null;
      _reportError('تعذر الاتصال بالتحديثات الفورية: $error');
      _scheduleReconnect();
    }
  }

  Future<void> _handleMessage(dynamic rawMessage) async {
    final message = _asMap(
      rawMessage is String ? jsonDecode(rawMessage) : rawMessage,
    );
    final event = message['event']?.toString();
    if (event == 'pusher:connection_established') {
      final data = _asMap(jsonDecode(message['data'] as String));
      await _subscribePrivateChannel(data['socket_id']?.toString());
      return;
    }
    if ((event == _eventName || event == '.$_eventName') &&
        message['data'] != null) {
      final data = _asMap(
        message['data'] is String
            ? jsonDecode(message['data'] as String)
            : message['data'],
      );
      final order = _asMap(data['order']);
      final action =
          data['action']?.toString() ??
          (data['status'] != null ? 'updated' : null);
      if (action == null || order.isEmpty) return;
      if (data['status'] != null && order['status'] == null) {
        order['status'] = data['status'];
      }
      _events.add(
        OrderRealtimeEvent(action: action, order: StoreOrder.fromJson(order)),
      );
    }
  }

  Future<void> _subscribePrivateChannel(String? socketId) async {
    if (_subscribed || _socket == null || socketId == null) return;
    final userId = await _ensureUserId();
    if (userId == null || userId.isEmpty) return;
    final channelName = 'user-orders-channel.$userId';
    final channel = 'private-$channelName';
    try {
      final response = await _api.dio.post<dynamic>(
        'broadcasting/auth',
        options: Options(
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
        data: {'socket_id': socketId, 'channel_name': channel},
      );
      final auth = _asMap(response.data)['auth']?.toString();
      if (auth == null || auth.isEmpty) {
        throw StateError('لم يرجع الخادم بيانات مصادقة قناة الطلبات.');
      }
      _subscribed = true;
      _socket!.sink.add(
        jsonEncode({
          'event': 'pusher:subscribe',
          'data': {'auth': auth, 'channel': channel},
        }),
      );
    } catch (error) {
      _reportError('فشلت مصادقة قناة الطلبات: $error');
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _socket = null;
    _subscribed = false;
    if (_closed || _reconnectTimer != null) return;
    _reconnectTimer = Timer(const Duration(seconds: 3), () {
      _reconnectTimer = null;
      connect();
    });
  }

  Future<String?> _ensureUserId() async {
    final cached = await CacheHelper.getSecureData(key: CacheConstants.userId);
    if (cached != null && cached.isNotEmpty) return cached;

    final token = await CacheHelper.getSecureData(
      key: CacheConstants.userToken,
    );
    if (token == null) return null;
    final parts = token.split('.');
    if (parts.length != 3) return null;
    try {
      final payload = _asMap(
        jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
        ),
      );
      final userId = payload['user_id'] ?? payload['sub'] ?? payload['id'];
      if (userId == null) return null;
      final value = userId.toString();
      await CacheHelper.saveSecureData(
        key: CacheConstants.userId,
        value: value,
      );
      return value;
    } catch (_) {
      return null;
    }
  }

  void _reportError(String message) {
    if (kDebugMode) debugPrint(message);
    if (!_errors.isClosed) _errors.add(message);
  }

  Future<void> close() async {
    _closed = true;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _socket?.sink.close();
    _socket = null;
    await _events.close();
    await _errors.close();
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }
}
