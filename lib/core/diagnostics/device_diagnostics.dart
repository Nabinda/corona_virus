// lib/core/diagnostics/device_diagnostics.dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceDiagnostics {
  static Future<Map<String, dynamic>> getDeviceInfo() async {
    final plugin = DeviceInfoPlugin();

    // 1. Guard against web runtime first
    if (kIsWeb) {
      final webInfo = await plugin.webBrowserInfo;
      return {
        'platform': 'Web',
        'browserName': webInfo.browserName.name,
        'userAgent': webInfo.userAgent ?? 'Unknown',
        'vendor': webInfo.vendor ?? 'Unknown',
        'hardwareConcurrency': webInfo.hardwareConcurrency,
        'maxTouchPoints': webInfo.maxTouchPoints,
      };
    }

    // 2. Native platforms safe to call Platform
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return {
        'platform': 'Android',
        'model': '${info.manufacturer} ${info.model}',
        'osVersion':
            'Android ${info.version.release} (SDK ${info.version.sdkInt})',
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    } else if (Platform.isIOS) {
      final info = await plugin.iosInfo;
      return {
        'platform': 'iOS',
        'model': info.utsname.machine,
        'osVersion': '${info.systemName} ${info.systemVersion}',
        'isPhysicalDevice': info.isPhysicalDevice,
      };
    }

    return {
      'platform': Platform.operatingSystem,
      'osVersion': Platform.operatingSystemVersion,
    };
  }
}
