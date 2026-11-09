import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../../../../core/logging/app_log_buffer.dart';
import '../../domain/services/answer/device_capability.dart';

class DeviceInfoCapability implements DeviceCapability {
  DeviceInfoCapability([DeviceInfoPlugin? plugin])
    : _plugin = plugin ?? DeviceInfoPlugin();

  final DeviceInfoPlugin _plugin;

  @override
  Future<int?> totalRamMb() async {
    try {
      if (Platform.isAndroid) {
        return (await _plugin.androidInfo).physicalRamSize;
      }
      if (Platform.isIOS) {
        return (await _plugin.iosInfo).physicalRamSize;
      }
    } catch (e, st) {
      AppLogBuffer.instance.captureError('device.ram', e, st);
    }
    return null;
  }
}
