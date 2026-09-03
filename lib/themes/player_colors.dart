import 'package:flutter/material.dart';

class PlayerColors {
  static const Color player1 = Color(0xffcc1104);
  static const Color player2 = Color(0xff209403);
  static const Color player3 = Color(0xff06b1c4);
  static const Color player4 = Color(0xff7407b8);
  static Color fromIndex(int sequence) {
    return switch (sequence) {
      1 => player1,
      2 => player2,
      3 => player3,
      4 => player4,
      _ => Colors.grey, // Clear fallback for invalid input
    };
  }
}
