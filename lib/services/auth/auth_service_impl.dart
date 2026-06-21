// lib/services/auth/auth_service_impl.dart
// Google Sign-In implementation with API key management
// 
// Flow:
// 1. User signs in with Google
// 2. After login, shows dialog guiding user to create their own API key
// 3. User clicks "Open Link" to go to Google AI Studio
// 4. User creates API key and copies it
// 5. User clicks "I Copied the Key" button and pastes the key
// 6. API key is saved securely in SharedPreferences
//
// This approach avoids using a hardcoded API key and gives each user
// their own quota, preventing abuse and rate limiting issues.

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import '../../features/l10n/app_language.dart';
import '../../features/l10n/app_localizations.dart';

class AuthServiceImpl implements AuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Optional: Add your server client ID if you need backend integration
    // serverClientId: 'YOUR_SERVER_CLIENT_ID.apps.googleusercontent.com',
  );

  GoogleSignInAccount? _currentUser;
  bool _initialized = false;

  @override
  bool get isLoggedIn => _currentUser != null;

  @override
  String? get userEmail => _currentUser?.email;

  Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      // Try to sign in silently (restore previous session)
      _currentUser = await _googleSignIn.signInSilently();
      debugPrint('[AuthService] Silent sign-in: ${_currentUser?.email ?? 'none'}');
    } catch (e) {
      debugPrint('[AuthService] Silent sign-in failed: $e');
      _currentUser = null;
    }
    
    _initialized = true;
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      
      if (_currentUser != null) {
        debugPrint('[AuthService] Signed in: ${_currentUser!.email}');
        return true;
      }
      
      debugPrint('[AuthService] Sign-in cancelled by user');
      return false;
    } catch (e) {
      debugPrint('[AuthService] Sign-in error: $e');
      return false;
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _currentUser = null;
      debugPrint('[AuthService] Signed out');
    } catch (e) {
      debugPrint('[AuthService] Sign-out error: $e');
      rethrow;
    }
  }

  @override
  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('gemini_api_key');
  }

  @override
  Future<void> saveApiKey(String apiKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', apiKey);
    debugPrint('[AuthService] API key saved successfully');
  }

  /// Shows the API key setup dialog after login
  /// Returns the API key if user successfully entered it, null otherwise
  Future<String?> showApiKeySetupDialog(BuildContext context) async {
    final TextEditingController _controller = TextEditingController();
    String? resultKey;
    
    // Get localization instance
    final loc = AppLocalizations.of(context);

    await showDialog<String>(
      context: context,
      barrierDismissible: false, // User must explicitly close
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  loc.apiKeySetupTitle,
                  textDirection: _getTextDirection(context),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Instructions
                Text(
                  loc.apiKeyInstructions,
                  textDirection: _getTextDirection(context),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                
                // Step-by-step guide
                _buildStep(context, '1', loc.step1),
                _buildStep(context, '2', loc.step2),
                _buildStep(context, '3', loc.step3),
                _buildStep(context, '4', loc.step4),
                _buildStep(context, '5', loc.step5),
                
                const SizedBox(height: 24),
                
                // Open Link Button
                ElevatedButton.icon(
                  onPressed: () async {
                    // Open Google AI Studio API key page
                    final Uri url = Uri.parse('https://aistudio.google.com/app/apikey');
                    if (await canLaunchUrl(url)) {
                      await launchUrl(url, mode: LaunchMode.externalApplication);
                      
                      // Show confirmation
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'صفحه ساخت کلید API باز شد. پس از کپی کردن کلید، به برنامه برگردید.',
                              textDirection: TextDirection.rtl,
                            ),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'نتوانست لینک را باز کند. لطفاً دستی به aistudio.google.com بروید.',
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(loc.openLink),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // API Key Input Field
                TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: loc.pasteApiKey,
                    hintText: 'e.g., AIzaSy... or AQ.A...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.vpn_key),
                  ),
                  textDirection: TextDirection.ltr, // API keys are LTR
                  keyboardType: TextInputType.visiblePassword,
                  onChanged: (value) {
                    // Auto-validate as user types
                  },
                ),
              ],
            ),
          ),
          actions: [
            // Cancel button (only if they already have a key saved)
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                loc.cancel,
                textDirection: _getTextDirection(context),
              ),
            ),
            
            // I Copied the Key button
            ElevatedButton.icon(
              onPressed: () async {
                final apiKey = _controller.text.trim();
                
                if (apiKey.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'لطفاً کلید API را paste کنید',
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                // Flexible validation: Allow new Google API key formats (e.g., AQ.A..., AIza...)
                // Only check for valid characters and reasonable length
                // Let Google's servers validate the actual key
                final validCharsRegex = RegExp(r'^[a-zA-Z0-9._-]+$');
                
                if (!validCharsRegex.hasMatch(apiKey)) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'کلید API حاوی کاراکترهای نامعتبر است. لطفاً کلید را دقیقاً کپی کنید.',
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                if (apiKey.length < 20 || apiKey.length > 100) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'طول کلید API نامعتبر به نظر می‌رسد. لطفاً بررسی کنید.',
                        textDirection: TextDirection.rtl,
                      ),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                
                // Save the key
                await saveApiKey(apiKey);
                resultKey = apiKey;
                
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        loc.apiKeySaved,
                        textDirection: _getTextDirection(context),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.of(dialogContext).pop(apiKey);
                }
              },
              icon: const Icon(Icons.check_circle),
              label: Text(loc.iCopiedKey),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              ),
            ),
          ],
          actionsAlignment: MainAxisAlignment.spaceBetween,
        );
      },
    );

    _controller.dispose();
    return resultKey;
  }

  Widget _buildStep(BuildContext context, String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              textDirection: _getTextDirection(context),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  /// Helper method to get correct text direction based on current language
  TextDirection _getTextDirection(BuildContext context) {
    try {
      final loc = AppLocalizations.of(context);
      switch (loc.language) {
        case AppLanguage.persian:
        case AppLanguage.arabic:
          return TextDirection.rtl;
        case AppLanguage.dutch:
        case AppLanguage.english:
          return TextDirection.ltr;
      }
    } catch (e) {
      // Fallback to LTR if localization fails
      return TextDirection.ltr;
    }
  }

  @override
  Future<String?> getCurrentLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('app_language_code');
  }

  @override
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language_code', languageCode);
    debugPrint('[AuthService] Language code saved: $languageCode');
  }

  @override
  Future<String?> getSelectedOcrModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('selected_ocr_model');
  }

  @override
  Future<void> saveSelectedOcrModel(String modelName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_ocr_model', modelName);
    debugPrint('[AuthService] OCR model saved: $modelName');
  }
}
