import 'package:flutter/material.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Pre-warm painting pipeline to reduce first-frame jank, especially with gradients.
  PaintingBinding.instance.ensureVisualUpdate();
  runApp(const SSIApp());
}