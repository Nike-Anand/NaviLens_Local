import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:navilens_local/ui/theme/app_settings.dart';
import 'package:navilens_local/ui/theme/app_theme.dart';
import 'package:navilens_local/ui/splash/splash_screen.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint('Error fetching cameras: $e');
  }
  runApp(const NaviLensApp());
}

class NaviLensApp extends StatelessWidget {
  const NaviLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AppSettingsScope(
      settings: AppSettings.instance,
      child: MaterialApp(
        title: 'NaviLens Local',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const SplashScreen(),
        // Apply the global "Large Text" accessibility setting.
        builder: (context, child) {
          final settings = AppSettingsScope.of(context);
          final base = MediaQuery.of(context);
          final scaled = base.copyWith(
            textScaler: settings.largeText
                ? const TextScaler.linear(1.25)
                : TextScaler.noScaling,
          );
          return MediaQuery(data: scaled, child: child!);
        },
      ),
    );
  }
}
