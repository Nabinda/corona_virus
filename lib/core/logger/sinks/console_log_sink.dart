import 'dart:developer' as developer;
import '../ansi_colors.dart';
import '../log_level.dart';
import '../log_sink.dart';

class ConsoleLogSink implements LogSink {
  final LogLevel minLevel;

  ConsoleLogSink({this.minLevel = LogLevel.debug});

  @override
  void write({
    required DateTime timestamp,
    required LogLevel level,
    required String message,
    Map<String, dynamic>? data,
    Duration? duration,
  }) {
    if (level.index < minLevel.index) return;

    final time =
        '${AnsiColors.gray}${timestamp.toIso8601String().substring(11, 23)}${AnsiColors.reset}';
    final tagColor = _resolveColor(message, level);

    final durationStr = duration != null
        ? ' ${duration.inMilliseconds > 100 ? AnsiColors.orange : AnsiColors.green}[${duration.inMilliseconds}ms]${AnsiColors.reset}'
        : '';

    final metaStr = (data != null && data.isNotEmpty)
        ? ' ${AnsiColors.gray}(${data.entries.map((e) => '${e.key}: ${e.value}').join(', ')})${AnsiColors.reset}'
        : '';

    developer.log(
      '$time $tagColor${AnsiColors.bold}[$message]${AnsiColors.reset}$durationStr$metaStr',
      name: 'GAME',
    );
  }

  String _resolveColor(String message, LogLevel level) {
    if (message.contains('ELIMINATED')) return AnsiColors.red;
    if (message.contains('EXPLOSION')) return AnsiColors.yellow;
    if (message.contains('SPREAD')) return AnsiColors.magenta;
    if (message.contains('REACTION_COMPLETED')) return AnsiColors.green;
    if (message.contains('MOVE')) return AnsiColors.cyan;

    return switch (level) {
      LogLevel.debug => AnsiColors.gray,
      LogLevel.info => AnsiColors.cyan,
      LogLevel.warning => AnsiColors.orange,
      LogLevel.error || LogLevel.critical => AnsiColors.red,
    };
  }

  @override
  Future<void> dispose() async {}
}
