import 'dart:io';

import 'package:flutter/services.dart';

import '../../domain/entities/captured_transaction.dart';
import '../../domain/repositories/sms_capture_repository.dart';

/// Reads the Android SMS inbox through the `MainActivity` method channel.
class MethodChannelSmsInbox implements SmsInbox {
  static const _channel = MethodChannel('com.nextgen.expenseflow/sms');

  @override
  bool get isSupported => Platform.isAndroid;

  @override
  Future<bool> hasPermission() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('hasPermission') ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!isSupported) return false;
    return await _channel.invokeMethod<bool>('requestPermission') ?? false;
  }

  @override
  Future<List<RawSms>> readSince(DateTime since, {int limit = 500}) async {
    if (!isSupported) return const [];

    final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
      'readInbox',
      {'sinceMillis': since.millisecondsSinceEpoch, 'limit': limit},
    );

    return [
      for (final m in raw ?? const <Map<Object?, Object?>>[])
        if (m['id'] is String && m['body'] is String && m['date'] is int)
          RawSms(
            id: m['id']! as String,
            sender: (m['address'] as String?) ?? '',
            body: m['body']! as String,
            receivedAt: DateTime.fromMillisecondsSinceEpoch(m['date']! as int),
          ),
    ];
  }
}
