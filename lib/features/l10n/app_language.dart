import 'package:flutter/material.dart';

/// Supported languages for the app UI
enum AppLanguage {
  persian('fa', 'فارسی'),
  dutch('nl', 'Nederlands'),
  arabic('ar', 'العربية'),
  english('en', 'English');

  final String code;
  final String nativeName;

  const AppLanguage(this.code, this.nativeName);

  /// Get language from code string
  static AppLanguage fromCode(String code) {
    switch (code.toLowerCase()) {
      case 'fa':
        return AppLanguage.persian;
      case 'nl':
        return AppLanguage.dutch;
      case 'ar':
        return AppLanguage.arabic;
      case 'en':
        return AppLanguage.english;
      default:
        return AppLanguage.persian; // Default fallback
    }
  }

  Locale get locale {
    switch (this) {
      case AppLanguage.persian:
        return const Locale('fa');
      case AppLanguage.dutch:
        return const Locale('nl');
      case AppLanguage.arabic:
        return const Locale('ar');
      case AppLanguage.english:
        return const Locale('en');
    }
  }

  TextDirection get textDirection {
    switch (this) {
      case AppLanguage.persian:
      case AppLanguage.arabic:
        return TextDirection.rtl;
      case AppLanguage.dutch:
      case AppLanguage.english:
        return TextDirection.ltr;
    }
  }
}
