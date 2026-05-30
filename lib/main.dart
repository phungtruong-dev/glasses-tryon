import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Camera list used by mobile (iOS/Android) AR screens.
/// Empty on macOS — camera_macos handles discovery there.
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!Platform.isMacOS) {
    try {
      cameras = await availableCameras();
    } catch (e) {
      debugPrint('Không lấy được camera: $e');
    }
  }
  runApp(const GlassesTryOnApp());
}

class GlassesTryOnApp extends StatelessWidget {
  const GlassesTryOnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thử Kính AR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF274690),
        brightness: Brightness.light,
      ),
      home: const HomeScreen(),
    );
  }
}
