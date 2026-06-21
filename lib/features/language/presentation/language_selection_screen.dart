import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../features/l10n/app_language.dart';
import '../../../features/l10n/app_localizations.dart';

/// Provider for the current app language
final appLanguageProvider = StateNotifierProvider<AppLanguageNotifier, AppLanguage>(
  (ref) => AppLanguageNotifier(),
);

class AppLanguageNotifier extends StateNotifier<AppLanguage> {
  AppLanguageNotifier() : super(AppLanguage.english);

  Future<void> loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final langCode = prefs.getString('app_language') ?? 'en';
    
    AppLanguage language;
    switch (langCode) {
      case 'fa':
        language = AppLanguage.persian;
        break;
      case 'nl':
        language = AppLanguage.dutch;
        break;
      case 'ar':
        language = AppLanguage.arabic;
        break;
      default:
        language = AppLanguage.english;
    }
    
    state = language;
  }

  Future<void> setLanguage(AppLanguage language) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_language', language.code);
    state = language;
  }
}

/// Language selection screen shown at app startup
class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends ConsumerState<LanguageSelectionScreen> {
  AppLanguage? _selectedLanguage;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App Icon/Logo
              Icon(
                Icons.menu_book_rounded,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 24),
              
              // Title
              Text(
                loc.selectLanguage,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              
              // Description
              Text(
                loc.languageDescription,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Language Options
              ...AppLanguage.values.map((language) => _buildLanguageTile(language, loc)),
              
              const SizedBox(height: 32),
              
              // Continue Button
              ElevatedButton(
                onPressed: _selectedLanguage != null ? _onContinue : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  loc.continueText,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageTile(AppLanguage language, AppLocalizations loc) {
    final isSelected = _selectedLanguage == language;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Theme.of(context).primaryColor : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () => setState(() => _selectedLanguage = language),
        borderRadius: BorderRadius.circular(12),
        customBorder: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Radio button
              Radio<AppLanguage>(
                value: language,
                groupValue: _selectedLanguage,
                onChanged: (value) => setState(() => _selectedLanguage = value),
              ),
              
              // Language name in native script
              Expanded(
                child: Text(
                  language.nativeName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              
              // Checkmark if selected
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _onContinue() {
    if (_selectedLanguage != null) {
      ref.read(appLanguageProvider.notifier).setLanguage(_selectedLanguage!);
      
      // Navigate to login screen
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }
}
