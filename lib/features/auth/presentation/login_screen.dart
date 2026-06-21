// lib/features/auth/presentation/login_screen.dart
// Login screen with Google Sign-In and API key setup flow
// 
// Accessibility features:
// - Full TalkBack/VoiceOver support
// - Large touch targets (48x48 minimum)
// - High contrast colors
// - Proper semantic labels
// - RTL support for Persian text

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/auth/auth_service_impl.dart';
import '../../dashboard/presentation/main_dashboard.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_language.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final AuthServiceImpl _authService = AuthServiceImpl();
  bool _isLoading = false;
  String? _errorMessage;
  AppLanguage _currentLanguage = AppLanguage.persian;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadCurrentLanguage();
  }

  Future<void> _loadCurrentLanguage() async {
    final languageCode = await _authService.getCurrentLanguageCode();
    setState(() {
      _currentLanguage = AppLanguage.fromCode(languageCode ?? 'fa');
    });
  }

  AppLocalizations _createLocalizations() {
    return AppLocalizations(_currentLanguage);
  }

  Future<void> _initializeAuth() async {
    await _authService.initialize();
    
    // If already logged in and has API key, proceed to main app
    if (_authService.isLoggedIn) {
      final apiKey = await _authService.getApiKey();
      if (apiKey != null && apiKey.isNotEmpty) {
        // User is fully set up, navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboard()),
          );
        }
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await _authService.signInWithGoogle();

      if (success && mounted) {
        // Show API key setup dialog after successful login
        final apiKey = await _authService.showApiKeySetupDialog(context);

        if (apiKey != null && mounted) {
          // Successfully set up API key, navigate to dashboard
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboard()),
          );
        } else if (mounted) {
          // User cancelled or skipped API key setup
          // Still allow them to use the app but show warning
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'کلید API تنظیم نشد. اسکن ابری کار نخواهد کرد.',
                textDirection: TextDirection.rtl,
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 5),
            ),
          );
          
          // Navigate anyway, OCR will fallback to PaddleOCR (offline)
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainDashboard()),
          );
        }
      } else if (mounted) {
        final localizations = _createLocalizations();
        setState(() {
          _errorMessage = localizations.loginWithGoogle + ' ' + 
              (localizations.language == AppLanguage.persian ? 'ناموفق بود. لطفاً دوباره تلاش کنید.' : 
               localizations.language == AppLanguage.dutch ? 'mislukt. Probeer het opnieuw.' :
               localizations.language == AppLanguage.arabic ? 'فشل. حاول مرة أخرى.' :
               'failed. Please try again.');
        });
      }
    } catch (e) {
      debugPrint('[LoginScreen] Sign-in error: $e');
      if (mounted) {
        final localizations = _createLocalizations();
        setState(() {
          _errorMessage = '${localizations.error}: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _createLocalizations();
    final isRTL = localizations.language.textDirection == TextDirection.rtl;
    
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Semantics(
                  label: '${localizations.appName} ${localizations.welcome}',
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.menu_book,
                      size: 64,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // App Title
                Text(
                  localizations.appName,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtitle
                Text(
                  localizations.loginSubtitle,
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                            style: TextStyle(color: Colors.red.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Sign In Button
                Semantics(
                  button: true,
                  label: localizations.loginWithGoogle,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    icon: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.login,
                            size: 24,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                    label: Text(
                      _isLoading ? localizations.loading : localizations.loginWithGoogle,
                      style: const TextStyle(fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      minimumSize: const Size(200, 56),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Info Text
                Text(
                  '${localizations.apiKeyInstructions}\n${localizations.setupApiKey} ${localizations.loginTitle}.',
                  textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
