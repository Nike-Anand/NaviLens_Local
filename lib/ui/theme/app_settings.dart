import 'package:flutter/widgets.dart';

/// Global, presentation-only accessibility settings.
///
/// These live in the presentation layer and drive rendering (text scaling,
/// contrast and navigation simplification). They do not alter any AI / ML
/// behaviour.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  bool _highContrast = false;
  bool _largeText = false;
  bool _simpleNavigation = false;

  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get simpleNavigation => _simpleNavigation;

  set highContrast(bool value) {
    if (_highContrast == value) return;
    _highContrast = value;
    notifyListeners();
  }

  set largeText(bool value) {
    if (_largeText == value) return;
    _largeText = value;
    notifyListeners();
  }

  set simpleNavigation(bool value) {
    if (_simpleNavigation == value) return;
    _simpleNavigation = value;
    notifyListeners();
  }
}

/// Inherited widget exposing [AppSettings] to the widget tree and rebuilding
/// dependents whenever a setting changes.
class AppSettingsScope extends InheritedNotifier<AppSettings> {
  const AppSettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppSettingsScope>();
    return scope?.notifier ?? AppSettings.instance;
  }
}