// lib/main.dart
import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'core/diagnostics/device_diagnostics.dart';
import 'core/diagnostics/fps_tracker.dart';
import 'core/logger/app_logger.dart';
import 'core/logger/log_level.dart';
import 'core/logger/sinks/console_log_sink.dart';
import 'core/logger/sinks/telemetry_sink.dart';

void main() async {
  // 1. Ensure bindings are initialized first in the root zone
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Profiling & Hardware Diagnostics
  final deviceMetadata = await DeviceDiagnostics.getDeviceInfo();

  // 3. Telemetry & Log Stack Initialization
  // Initialize the singleton
  await TelemetrySink.instance.init(deviceMetadata);
  final logger = AppLogger([
    ConsoleLogSink(
      minLevel: kReleaseMode ? LogLevel.warning : LogLevel.debug,
    ),
    TelemetrySink.instance,
  ]);
  FpsTracker.instance.init(logger);
  FpsTracker.instance.start();
  final logPath = await TelemetrySink.instance.getLogPath();
  debugPrint('>>> TELEMETRY WRITING TO: $logPath');

  void handleFatalCrash(String source, Object error, StackTrace? stack) {
    logger.error('Fatal [$source]: $error', error: error, stackTrace: stack);
    unawaited(TelemetrySink.instance.dumpRingBufferOnCrash(error, stack));
  }

  // 4. Trap Flutter Framework / Widget build errors
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    handleFatalCrash('FlutterError', details.exception, details.stack);
  };

  // 5. Trap Asynchronous / Platform / Native errors across the entire application
  PlatformDispatcher.instance.onError = (error, stack) {
    handleFatalCrash('PlatformDispatcher', error, stack);
    return true; // Prevents app process termination
  };

  // 6. Run app directly in the same zone where bindings were initialized
  runApp(const App());
}
