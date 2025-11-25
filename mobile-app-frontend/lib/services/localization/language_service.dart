import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageService {
  static const String _languageKey = 'app_language';
  static const Locale defaultLocale = Locale('en', 'US');
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('vi', 'VN'),
  ];

  /// Get saved language locale
  static Future<Locale> getSavedLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey);
    
    if (languageCode == null) {
      return defaultLocale;
    }
    
    // Parse locale from saved string (e.g., "en_US" or "vi_VN")
    final parts = languageCode.split('_');
    if (parts.length == 2) {
      return Locale(parts[0], parts[1]);
    }
    
    return defaultLocale;
  }

  /// Save language locale
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, '${locale.languageCode}_${locale.countryCode}');
  }

  /// Get locale display name
  static String getLocaleDisplayName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English (US)';
      case 'vi':
        return 'Tiếng Việt (VN)';
      default:
        return locale.toString();
    }
  }
}

