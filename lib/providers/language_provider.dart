import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class LanguageProvider extends ChangeNotifier {
  Locale _locale = const Locale('en'); // Default to English
  final Box _settingsBox;

  LanguageProvider(this._settingsBox) {
    _loadLanguage();
  }

  Locale get locale => _locale;

  String get languageCode => _locale.languageCode;

  String get languageName {
    switch (_locale.languageCode) {
      case 'bn':
        return 'বাংলা';
      case 'en':
      default:
        return 'English';
    }
  }

  Future<void> _loadLanguage() async {
    final savedLanguage = _settingsBox.get('language', defaultValue: 'en');
    _locale = Locale(savedLanguage);
    notifyListeners();
  }

  Future<void> changeLanguage(String languageCode) async {
    if (_locale.languageCode == languageCode) return;

    _locale = Locale(languageCode);
    await _settingsBox.put('language', languageCode);
    notifyListeners();
  }

  List<Map<String, String>> get supportedLanguages => [
        {'code': 'en', 'name': 'English'},
        {'code': 'bn', 'name': 'বাংলা'},
      ];
}
