import 'package:corona_virus/features/game/presentation/game_screen.dart';
import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Corona Virus',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}
