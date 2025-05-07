import 'package:flutter/material.dart';
import 'features/home/presentation/screens/home_screen.dart';
import 'features/match/presentation/screens/new_match_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelada de Vôlei',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
        '/new-match': (context) => const NewMatchScreen(),
      },
    );
  }
}

