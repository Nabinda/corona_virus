// lib/core/logger/sinks/telemetry_sink.dart
import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:web/web.dart' as web;

import '../log_level.dart';
import '../log_sink.dart';

class TelemetrySink implements LogSink {
  // Static singleton instance
  static final TelemetrySink instance = TelemetrySink._internal();

  TelemetrySink._internal();

  final String fileName = 'game_telemetry.log';
  final int ringBufferSize = 1000;
  final DoubleLinkedQueue<String> _ringBuffer = DoubleLinkedQueue<String>();

  io.IOSink? _sessionSink;
  io.File? _sessionFile;
  io.File? _crashDumpFile;
  final StringBuffer _webSessionBuffer = StringBuffer();
  bool _isInitialized = false;

  Future<void> init(Map<String, dynamic> metadata) async {
    if (_isInitialized) return;
    _isInitialized = true;

    final metaHeader = StringBuffer()
      ..writeln('=== DEVICE & RUNTIME PROFILE ===');
    metadata.forEach((k, v) => metaHeader.writeln('$k: $v'));
    metaHeader.writeln('================================\n');

    if (kIsWeb) {
      _webSessionBuffer.write(metaHeader.toString());
      web.window.localStorage
          .setItem('game_telemetry', _webSessionBuffer.toString());
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _sessionFile = io.File('${dir.path}/$fileName');
    _crashDumpFile = io.File('${dir.path}/crash_dump.log');

    _sessionSink = _sessionFile!.openWrite(mode: io.FileMode.write);
    _sessionSink?.write(metaHeader.toString());
  }

  Future<String> getLogPath() async {
    if (kIsWeb) {
      return 'Browser LocalStorage (Keys: "game_telemetry" & "crash_dump")';
    }
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/$fileName';
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
      if (kIsWeb) {
        _webSessionBuffer.writeln(formatted);
        if (error != null) _webSessionBuffer.writeln('  ↳ Error: $error');
        if (stackTrace != null)
          _webSessionBuffer.writeln('  ↳ StackTrace:\n$stackTrace');
        web.window.localStorage
            .setItem('game_telemetry', _webSessionBuffer.toString());
      } else {
        _sessionSink?.writeln(formatted);
        if (error != null) _sessionSink?.writeln('  ↳ Error: $error');
        if (stackTrace != null)
          _sessionSink?.writeln('  ↳ StackTrace:\n$stackTrace');
      }
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

    if (kIsWeb) {
      web.window.localStorage.setItem('crash_dump', dump.toString());
      _triggerBrowserDownload('crash_dump.log', dump.toString());
      return;
    }

    if (_crashDumpFile != null) {
      final sink = _crashDumpFile!.openWrite(mode: io.FileMode.write);
      sink.write(dump.toString());
      await sink.flush();
      await sink.close();
    }
  }

  /// Exports a complete snapshot (Profile + Session Milestones + Last N Micro-actions)
  Future<String?> exportSessionLogs() async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final exportFileName = 'game_diagnostics_$timestamp.log';

    // 1. Build the micro-action / FPS ring buffer section
    final ringBufferDump = StringBuffer()
      ..writeln(
          '\n=== RECENT MICRO-EVENTS & FPS TRACE (Last ${_ringBuffer.length}) ===');
    for (final entry in _ringBuffer) {
      ringBufferDump.writeln(entry);
    }
    ringBufferDump
        .writeln('==================================================\n');

    // 2. Handle Web target
    if (kIsWeb) {
      final webContent = StringBuffer()
        ..write(_webSessionBuffer.toString())
        ..write(ringBufferDump.toString());

      _triggerBrowserDownload(exportFileName, webContent.toString());
      return 'Downloaded via browser: $exportFileName';
    }

    // 3. Handle Native targets (Android, iOS, macOS, Windows, Linux)
    try {
      await _sessionSink?.flush();

      final dir = await getApplicationDocumentsDirectory();
      final exportFile = io.File('${dir.path}/$exportFileName');

      // Read existing session log (Device profile + turn summaries)
      String baseSessionData = '';
      if (_sessionFile != null && await _sessionFile!.exists()) {
        baseSessionData = await _sessionFile!.readAsString();
      }

      // Merge base session + memory ring buffer into the final export file
      await exportFile.writeAsString(
        '$baseSessionData\n${ringBufferDump.toString()}',
        flush: true,
      );

      debugPrint('>>> LOG EXPORT SUCCESS: ${exportFile.path}');
      return exportFile.path;
    } catch (e) {
      debugPrint('>>> FAILED TO EXPORT LOGS: $e');
      return null;
    }
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
  Future<void> dispose() async {
    if (!kIsWeb) {
      await _sessionSink?.flush();
      await _sessionSink?.close();
    }
  }
}
