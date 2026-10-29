import 'dart:convert';

import 'package:flutter/services.dart';

abstract interface class AppStorage {
  Future<Map<String, Object?>> read();
  Future<void> write(Map<String, Object?> state);
}

class DeviceStorage implements AppStorage {
  static const _channel = MethodChannel('app.luma.convert/storage');

  @override
  Future<Map<String, Object?>> read() async {
    try {
      final encoded = await _channel.invokeMethod<String>('read');
      if (encoded == null) return {};
      final value = jsonDecode(encoded);
      return value is Map<String, dynamic> ? value : {};
    } on FormatException {
      return {};
    }
  }

  @override
  Future<void> write(Map<String, Object?> state) async {
    await _channel.invokeMethod<void>('write', jsonEncode(state));
  }
}
