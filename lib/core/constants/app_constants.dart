/// Application-wide constants
class AppConstants {
  // Default language code
  static const String defaultLanguageCode = 'fa';

  // Default OCR model - Gemini 2.5 Flash (fastest & most accurate)
  static const String defaultOcrModel = 'gemini-2.5-flash';

  // Fallback OCR models if API fails to fetch available models
  // Only includes the 4 latest Gemini models + PaddleOCR
  static const List<String> fallbackOcrModels = [
    'gemini-2.5-flash',
    'gemini-2.5-flash-lite',
    'gemini-3.1-flash',
    'gemini-3.5-flash-lite',
  ];

  // Rate limiting configuration for Gemini API
  // 10 seconds between requests to stay within RPM limits (5-10 RPM)
  static const Duration geminiRequestInterval = Duration(seconds: 10);

  // Shared preferences keys
  static const String apiKeyPrefKey = 'api_key';
  static const String appLanguagePrefKey = 'app_language';
  static const String appLanguageCodePrefKey = 'app_language_code';
  static const String ocrModelPrefKey = 'selected_ocr_model'; // Match settings_tab.dart key
}
