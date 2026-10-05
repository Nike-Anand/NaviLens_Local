import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:navilens_local/ui/splash/splash_screen.dart';
import 'package:navilens_local/ui/theme/app_settings.dart';
import 'package:navilens_local/ui/theme/app_theme.dart';

List<CameraDescription> cameras = [];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
  );

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
        themeMode: ThemeMode.dark,
        home: const SplashScreen(),
        builder: (context, child) {
          final settings = AppSettingsScope.of(context);
          final mediaQuery = MediaQuery.of(context);

          final textScale = settings.largeText ? 1.20 : 1.0;

          final scaledMediaQuery = mediaQuery.copyWith(
            textScaler: TextScaler.linear(textScale),
          );

          return MediaQuery(
            data: scaledMediaQuery,
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}