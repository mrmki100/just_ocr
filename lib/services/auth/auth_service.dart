// lib/services/auth/auth_service.dart
// Abstract authentication service interface

import 'package:flutter/material.dart';

abstract class AuthService {
  Future<bool> signInWithGoogle();
  Future<void> signOut();
  Future<String?> getApiKey();
  Future<void> saveApiKey(String apiKey);
  bool get isLoggedIn;
  String? get userEmail;
  
  /// Shows the API key setup dialog after login
  /// Returns the API key if user successfully entered it, null otherwise
  Future<String?> showApiKeySetupDialog(BuildContext context);
  
  /// Get the current app language code from preferences
  Future<String?> getCurrentLanguageCode();
  
  /// Save the app language code to preferences
  Future<void> saveLanguageCode(String languageCode);
  
  /// Get the selected OCR model name from preferences
  Future<String?> getSelectedOcrModel();
  
  /// Save the selected OCR model name to preferences
  Future<void> saveSelectedOcrModel(String modelName);
}
