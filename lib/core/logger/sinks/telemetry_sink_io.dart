import 'dart:collection';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../log_level.dart';
import '../log_sink.dart';

class TelemetrySink implements LogSink {
  static final TelemetrySink instance = TelemetrySink._internal();
  TelemetrySink._internal();

  final String fileName = 'game_telemetry.log';
  final int ringBufferSize = 1000;
  final DoubleLinkedQueue<String> _ringBuffer = DoubleLinkedQueue<String>();

  io.IOSink? _sessionSink;
  io.File? _sessionFile;
  io.File? _crashDumpFile;
  bool _isInitialized = false;

  Future<void> init(Map<String, dynamic> metadata) async {
    if (_isInitialized) return;
    _isInitialized = true;

    final metaHeader = StringBuffer()
      ..writeln('=== DEVICE & RUNTIME PROFILE ===');
    metadata.forEach((k, v) => metaHeader.writeln('$k: $v'));
    metaHeader.writeln('================================\n');

    final dir = await getApplicationDocumentsDirectory();
    _sessionFile = io.File('${dir.path}/$fileName');
    _crashDumpFile = io.File('${dir.path}/crash_dump.log');

    _sessionSink = _sessionFile!.openWrite(mode: io.FileMode.write);
    _sessionSink?.write(metaHeader.toString());
  }

  Future<String> getLogPath() async {
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
      _sessionSink?.writeln(formatted);
      if (error != null) _sessionSink?.writeln('  ↳ Error: $error');
      if (stackTrace != null) {
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

    if (_crashDumpFile != null) {
      final sink = _crashDumpFile!.openWrite(mode: io.FileMode.write);
      sink.write(dump.toString());
      await sink.flush();
      await sink.close();
    }
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

    try {
      await _sessionSink?.flush();

      final dir = await getApplicationDocumentsDirectory();
      final exportFile = io.File('${dir.path}/$exportFileName');

      String baseSessionData = '';
      if (_sessionFile != null && await _sessionFile!.exists()) {
        baseSessionData = await _sessionFile!.readAsString();
      }

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

  @override
  Future<void> dispose() async {
    await _sessionSink?.flush();
    await _sessionSink?.close();
  }
}
