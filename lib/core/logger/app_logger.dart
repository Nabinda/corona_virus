import 'log_level.dart';
import 'log_sink.dart';

class AppLogger {
  final List<LogSink> _sinks;

  AppLogger(this._sinks);

  void log(
    LogLevel level,
    String message, {
    Map<String, dynamic>? data,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) {
    final now = DateTime.now();
    for (final sink in _sinks) {
      sink.write(
        timestamp: now,
        level: level,
        message: message,
        data: data,
        duration: duration,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void debug(
    String msg, {
    Map<String, dynamic>? data,
    Duration? duration,
  }) =>
      log(LogLevel.debug, msg, data: data, duration: duration);

  void info(
    String msg, {
    Map<String, dynamic>? data,
    Duration? duration,
  }) =>
      log(LogLevel.info, msg, data: data, duration: duration);

  void warning(
    String msg, {
    Map<String, dynamic>? data,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        LogLevel.warning,
        msg,
        data: data,
        duration: duration,
        error: error,
        stackTrace: stackTrace,
      );

  void error(
    String msg, {
    Map<String, dynamic>? data,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  }) =>
      log(
        LogLevel.error,
        msg,
        data: data,
        duration: duration,
        error: error,
        stackTrace: stackTrace,
      );

  Future<void> dispose() async {
    for (final sink in _sinks) {
      await sink.dispose();
    }
  }
}
