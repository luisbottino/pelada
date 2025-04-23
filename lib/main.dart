import 'package:flutter/material.dart';

void main() {
  runApp(const PeladaApp());
}

class PeladaApp extends StatelessWidget {
  const PeladaApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pelada',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pelada de Vôlei'),
      ),
      body: Center(
        child: ElevatedButton(onPressed: () {

        }, child: const Text('Começar')),
      ),
    );
  }
}

