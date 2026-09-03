class AnsiColors {
  static const String reset = '\x1B[0m';
  static const String bold = '\x1B[1m';

  // Text Colors
  static const String cyan = '\x1B[36m'; // Normal moves / Turns
  static const String yellow = '\x1B[33m'; // Reactions / Explosions
  static const String magenta = '\x1B[35m'; // Chain Spreads
  static const String green =
      '\x1B[32m'; // Successful performance / completions
  static const String red = '\x1B[31m'; // Eliminations / critical issues
  static const String orange =
      '\x1B[38;5;208m'; // Performance bottlenecks (>100ms)
  static const String gray = '\x1B[90m'; // Metadata / Timestamps
}
