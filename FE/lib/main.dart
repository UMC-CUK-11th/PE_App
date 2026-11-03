import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:movielog/app/movie_log_app.dart';

Future<void> main() async {
  await dotenv.load(isOptional: true);
  runApp(const MovieLogApp());
}
