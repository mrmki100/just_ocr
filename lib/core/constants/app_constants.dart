/// Application-wide constants
class AppConstants {
  // Default language code
  static const String defaultLanguageCode = 'fa';

  // Fallback OCR models if API fails to fetch available models
  // Updated to include the latest Gemini models
  static const List<String> fallbackOcrModels = [
    'gemini-2.5-flash',
    'gemini-2.0-flash',
    'gemini-1.5-flash',
  ];

  // Shared preferences keys
  static const String apiKeyPrefKey = 'api_key';
  static const String appLanguagePrefKey = 'app_language';
  static const String appLanguageCodePrefKey = 'app_language_code';
  static const String ocrModelPrefKey = 'selected_ocr_model'; // Match settings_tab.dart key
}
