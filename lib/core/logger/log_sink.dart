import 'log_level.dart';

abstract interface class LogSink {
  void write({
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? data,
    Duration? duration,
    Object? error,
    StackTrace? stackTrace,
  });

  Future<void> dispose();
}
