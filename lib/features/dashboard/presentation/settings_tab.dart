// lib/features/dashboard/presentation/settings_tab.dart
//
// Settings tab for app configuration
// Accessible settings with large touch targets and clear labels
//
// Accessibility features:
// - Full TalkBack/VoiceOver support
// - Large toggle switches and buttons
// - High contrast UI
// - RTL support
// - Dark mode support

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth/auth_service_impl.dart';
import '../../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_language.dart';

class SettingsTab extends ConsumerStatefulWidget {
  const SettingsTab({super.key});

  @override
  ConsumerState<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<SettingsTab> {
  // Settings state
  bool _ttsEnabled = true;
  double _ttsSpeed = 1.0;
  bool _highContrast = false;
  bool _largeText = false;
  String _selectedVoice = 'default';
  String? _apiKey;
  bool _isLoggedIn = false;
  String? _userEmail;
  AppLanguage _currentLanguage = AppLanguage.persian;
  
  final AuthServiceImpl _authService = AuthServiceImpl();

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadAuthStatus();
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

  Future<void> _loadAuthStatus() async {
    await _authService.initialize();
    final apiKey = await _authService.getApiKey();
    setState(() {
      _isLoggedIn = _authService.isLoggedIn;
      _userEmail = _authService.userEmail;
      _apiKey = apiKey;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ttsEnabled = prefs.getBool('tts_enabled') ?? true;
      _ttsSpeed = prefs.getDouble('tts_speed') ?? 1.0;
      _highContrast = prefs.getBool('high_contrast') ?? false;
      _largeText = prefs.getBool('large_text') ?? false;
      _selectedVoice = prefs.getString('selected_voice') ?? 'default';
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _handleSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'خروج از حساب',
          textDirection: TextDirection.rtl,
        ),
        content: Text(
          'آیا مطمئن هستید که می‌خواهید خارج شوید؟',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('لغو', textDirection: TextDirection.rtl),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('خروج', textDirection: TextDirection.rtl),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _authService.signOut();
      setState(() {
        _isLoggedIn = false;
        _userEmail = null;
        _apiKey = null;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('با موفقیت خارج شدید', textDirection: TextDirection.rtl),
          ),
        );
      }
    }
  }

  Future<void> _handleSetupApiKey() async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('لطفاً ابتدا وارد حساب گوگل خود شوید', textDirection: TextDirection.rtl),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final apiKey = await _authService.showApiKeySetupDialog(context);
    if (apiKey != null && mounted) {
      setState(() {
        _apiKey = apiKey;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('کلید API با موفقیت ذخیره شد', textDirection: TextDirection.rtl),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = _createLocalizations();
    final isRTL = localizations.language.textDirection == TextDirection.rtl;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Semantics(
            header: true,
            child: Text(
              localizations.settings,
              textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            localizations.accessibilitySettings,
            textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(context, localizations.accountSection),
          _buildAccountCard(context),
          
          const Divider(height: 32),

          // Text-to-Speech Section
          _buildSectionHeader(context, localizations.readAloud),
          _buildToggleTile(
            context,
            icon: Icons.volume_up,
            title: localizations.ttsSettings,
            subtitle: localizations.readAloud,
            value: _ttsEnabled,
            onChanged: (value) {
              setState(() => _ttsEnabled = value);
              _saveSetting('tts_enabled', value);
            },
          ),
          if (_ttsEnabled) ...[
            _buildSpeedSlider(context),
          ],

          const Divider(height: 32),

          // Accessibility Section
          _buildSectionHeader(context, localizations.accessibilitySettings),
          _buildToggleTile(
            context,
            icon: Icons.contrast,
            title: localizations.highContrastMode,
            subtitle: localizations.highContrastMode,
            value: _highContrast,
            onChanged: (value) {
              setState(() => _highContrast = value);
              _saveSetting('high_contrast', value);
            },
          ),
          _buildToggleTile(
            context,
            icon: Icons.text_fields,
            title: localizations.largeText,
            subtitle: localizations.largeText,
            value: _largeText,
            onChanged: (value) {
              setState(() => _largeText = value);
              _saveSetting('large_text', value);
            },
          ),

          const Divider(height: 32),

          // Appearance Section - Dark Mode Toggle
          _buildSectionHeader(context, localizations.settings),
          _buildThemeSelector(context),

          const Divider(height: 32),

          // About Section
          _buildSectionHeader(context, localizations.appName),
          _buildAboutTile(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final localizations = _createLocalizations();
    final isRTL = localizations.language.textDirection == TextDirection.rtl;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final localizations = _createLocalizations();
    final isRTL = localizations.language.textDirection == TextDirection.rtl;
    
    return Semantics(
      button: true,
      label: '$title: ${value ? (isRTL ? "فعال" : "Active") : (isRTL ? "غیرفعال" : "Inactive")}',
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        minLeadingWidth: 40,
        leading: Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        title: Text(
          title,
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          subtitle,
          textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.6),
              ),
        ),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          thumbIcon: MaterialStateProperty.resolveWith<Icon?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return const Icon(Icons.check);
              }
              return const Icon(Icons.close);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSpeedSlider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'سرعت خواندن:',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              Text(
                '${_ttsSpeed.toStringAsFixed(1)}x',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 6,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
              ),
            ),
            child: Slider(
              value: _ttsSpeed,
              min: 0.5,
              max: 2.0,
              divisions: 15,
              label: '${_ttsSpeed.toStringAsFixed(1)}x',
              onChanged: (value) {
                setState(() => _ttsSpeed = value);
                _saveSetting('tts_speed', value);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceSelector(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'صدای پیش‌فرض:',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedVoice,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
              ),
              items: [
                DropdownMenuItem(
                  value: 'default',
                  child: Text(
                    'پیش‌فرض سیستم',
                    textDirection: TextDirection.rtl,
                  ),
                ),
                // Add more voices as they become available
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedVoice = value);
                  _saveSetting('selected_voice', value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    
    return Semantics(
      label: 'انتخاب حالت تم',
      child: Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'حالت تم:',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.light,
                    label: Text('روشن'),
                    icon: Icon(Icons.light_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.dark,
                    label: Text('تاریک'),
                    icon: Icon(Icons.dark_mode),
                  ),
                  ButtonSegment<ThemeMode>(
                    value: ThemeMode.system,
                    label: Text('سیستم'),
                    icon: Icon(Icons.settings_suggest),
                  ),
                ],
                selected: {themeMode},
                onSelectionChanged: (Set<ThemeMode> selected) {
                  themeNotifier.setTheme(selected.first);
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: 12),
              Text(
                'تم فعلی: ${themeNotifier.themeName}',
                textDirection: TextDirection.rtl,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutTile(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.menu_book,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'justOCR',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'نسخه ۱.۰.۰',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Text(
              'برنامه‌ای برای اسکن و خواندن متون فارسی و انگلیسی\n'
              'با پشتیبانی از نابینایان و کم‌بینایان',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoggedIn) ...[
              // Logged in state
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: Text(
                      _userEmail?.substring(0, 1).toUpperCase() ?? 'U',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _userEmail ?? '',
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _apiKey != null && _apiKey!.isNotEmpty
                              ? 'کلید API: تنظیم شده ✓'
                              : 'کلید API: تنظیم نشده ⚠️',
                          textDirection: TextDirection.rtl,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: _apiKey != null && _apiKey!.isNotEmpty
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // Setup API Key Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _handleSetupApiKey,
                      icon: const Icon(Icons.key),
                      label: Text(localizations.setupApiKey),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Sign Out Button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleSignOut,
                      icon: const Icon(Icons.logout),
                      label: Text(localizations.signOut),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        foregroundColor: Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Not logged in state
              Text(
                localizations.loginRequired,
                textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    // Trigger login from settings
                    final success = await _authService.signInWithGoogle();
                    if (success && mounted) {
                      final apiKey = await _authService.showApiKeySetupDialog(context);
                      if (apiKey != null) {
                        setState(() {
                          _isLoggedIn = true;
                          _userEmail = _authService.userEmail;
                          _apiKey = apiKey;
                        });
                      }
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: Text(localizations.loginWithGoogle),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
