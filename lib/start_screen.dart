import 'package:flutter/material.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Icon(Icons.movie_outlined),
            Text('MovieLog'),
          ],
        ),
      ),
    );
  }
}