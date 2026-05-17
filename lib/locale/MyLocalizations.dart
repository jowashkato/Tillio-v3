import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations({required this.locale});

  // Access localization instance
  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
          context,
          AppLocalizations,
        ) ??
        AppLocalizations(locale: const Locale('en'));
  }

  // Localization delegate
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  Map<String, String> _localizedStrings = {};

  // Load language JSON
  Future<bool> load() async {
    try {
      String jsonString =
          await rootBundle.loadString('i18n/${locale.languageCode}.json');

      Map<String, dynamic> jsonMap = json.decode(jsonString);

      _localizedStrings = jsonMap.map(
        (key, value) => MapEntry(key, value.toString()),
      );

      return true;
    } catch (e) {
      debugPrint("Localization load error: $e");

      // fallback empty map
      _localizedStrings = {};

      return false;
    }
  }

  // Translate text safely
  String translate(String key) {
    return _localizedStrings[key] ?? key;
  }
}

// Localization delegate
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return Config().locale.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    AppLocalizations localizations = AppLocalizations(locale: locale);

    await localizations.load();

    return localizations;
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

// Language provider
class AppLanguage extends ChangeNotifier {
  Locale _appLocale = Locale(Config().defaultLanguage);

  Locale get appLocal => _appLocale;

  // Load saved language
  Future<void> fetchLocale() async {
    try {
      var prefs = await SharedPreferences.getInstance();

      if (prefs.getString('language_code') == null) {
        _appLocale = Locale(Config().defaultLanguage);

        await prefs.setString(
          'language_code',
          Config().defaultLanguage,
        );

        return;
      }

      _appLocale = Locale(
        prefs.getString('language_code')!,
      );
    } catch (e) {
      debugPrint("Fetch locale error: $e");

      _appLocale = Locale(Config().defaultLanguage);
    }
  }

  // Change app language
  Future<void> changeLanguage(
    Locale type,
    String value,
  ) async {
    try {
      var prefs = await SharedPreferences.getInstance();

      if (_appLocale == type) {
        return;
      }

      _appLocale = type;

      await prefs.setString('language_code', value);
      await prefs.setString('countryCode', '');

      notifyListeners();
    } catch (e) {
      debugPrint("Change language error: $e");
    }
  }
}
