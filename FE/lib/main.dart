import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/dart_practice.dart';
import 'package:movielog/movie_log_app.dart';

Future<void> main() async {
  await dotenv.load(isOptional: true);
  runDartPractice();
  runApp(const MovieLogApp());
}
