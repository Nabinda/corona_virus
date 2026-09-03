// lib/core/logger/sinks/telemetry_sink_web.dart
import 'dart:collection';
import 'dart:convert';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

import '../log_level.dart';
import '../log_sink.dart';

class TelemetrySink implements LogSink {
  static final TelemetrySink instance = TelemetrySink._internal();
  TelemetrySink._internal();

  final String fileName = 'game_telemetry.log';
  final int ringBufferSize = 1000;
  final DoubleLinkedQueue<String> _ringBuffer = DoubleLinkedQueue<String>();

  final StringBuffer _webSessionBuffer = StringBuffer();
  bool _isInitialized = false;

  Future<void> init(Map<String, dynamic> metadata) async {
    if (_isInitialized) return;
    _isInitialized = true;

    final metaHeader = StringBuffer()
      ..writeln('=== DEVICE & RUNTIME PROFILE ===');
    metadata.forEach((k, v) => metaHeader.writeln('$k: $v'));
    metaHeader.writeln('================================\n');

    _webSessionBuffer.write(metaHeader.toString());
    web.window.localStorage
        .setItem('game_telemetry', _webSessionBuffer.toString());
  }

  Future<String> getLogPath() async {
    return 'Browser LocalStorage (Keys: "game_telemetry" & "crash_dump")';
  }

  @override
  void write({
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? data,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final timeStr = timestamp.toIso8601String().substring(11, 23);
    final durationStr =
        duration != null ? ' [${duration.inMilliseconds}ms]' : '';
    final dataStr =
        (data != null && data.isNotEmpty) ? ' | ${jsonEncode(data)}' : '';

    final formatted =
        '[$timeStr] [${level.name.toUpperCase().padRight(5)}]$durationStr $message$dataStr';

    if (_ringBuffer.length >= ringBufferSize) {
      _ringBuffer.removeFirst();
    }
    _ringBuffer.addLast(formatted);

    final isSummaryOrCritical = level.index >= LogLevel.warning.index ||
        message.startsWith('[TURN_SUMMARY]') ||
        message.startsWith('[GAME_FINISHED]');

    if (isSummaryOrCritical) {
      _webSessionBuffer.writeln(formatted);
      if (error != null) _webSessionBuffer.writeln('  ↳ Error: $error');
      if (stackTrace != null)
        _webSessionBuffer.writeln('  ↳ StackTrace:\n$stackTrace');
      web.window.localStorage
          .setItem('game_telemetry', _webSessionBuffer.toString());
    }
  }

  Future<void> dumpRingBufferOnCrash(Object error, StackTrace? stack) async {
    final dump = StringBuffer()
      ..writeln('=== CRASH TRACE DUMP ===')
      ..writeln('Time: ${DateTime.now().toIso8601String()}')
      ..writeln('Error: $error')
      ..writeln('StackTrace:\n$stack')
      ..writeln('\n--- LAST $ringBufferSize MICRO-EVENTS ---');
    for (final line in _ringBuffer) {
      dump.writeln(line);
    }
    dump.writeln('========================');

    web.window.localStorage.setItem('crash_dump', dump.toString());
    _triggerBrowserDownload('crash_dump.log', dump.toString());
  }

  Future<String?> exportSessionLogs() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportFileName = 'game_diagnostics_$timestamp.log';

    final ringBufferDump = StringBuffer()
      ..writeln(
          '\n=== RECENT MICRO-EVENTS & FPS TRACE (Last ${_ringBuffer.length}) ===');
    for (final entry in _ringBuffer) {
      ringBufferDump.writeln(entry);
    }
    ringBufferDump
        .writeln('==================================================\n');

    final webContent = StringBuffer()
      ..write(_webSessionBuffer.toString())
      ..write(ringBufferDump.toString());

    _triggerBrowserDownload(exportFileName, webContent.toString());
    return 'Downloaded via browser: $exportFileName';
  }

  void _triggerBrowserDownload(String name, String content) {
    final blob = web.Blob(
      [content.toJS].toJS,
      web.BlobPropertyBag(type: 'text/plain'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement
      ..href = url
      ..download = name;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  @override
  Future<void> dispose() async {}
}
