import 'package:flutter/material.dart';

class NbaFantasyApp extends StatelessWidget {
  const NbaFantasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NBA Fantasy Stats',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(body: Center(child: Text('NBA Fantasy Stats'))),
    );
  }
}
