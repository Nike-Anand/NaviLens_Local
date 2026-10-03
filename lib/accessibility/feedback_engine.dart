import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';

class FeedbackEngine {
  static final FlutterTts _flutterTts = FlutterTts();

  static Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
  }

  static Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  static Future<void> stopSpeech() async {
    await _flutterTts.stop();
  }

  static Future<void> vibrateInfo() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  static Future<void> vibrateWarning() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 150, 100, 150]);
    }
  }

  static Future<void> vibrateHighPriority() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }
  }
}
