import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import 'screens/home_screen.dart';

/// Danh sách camera lấy 1 lần khi mở app, dùng chung cho màn AR.
List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    // Thiết bị/emulator không có camera -> vẫn vào app, màn try-on sẽ báo lỗi.
    debugPrint('Không lấy được camera: $e');
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
