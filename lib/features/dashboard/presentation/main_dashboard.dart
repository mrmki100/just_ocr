// lib/features/dashboard/presentation/main_dashboard.dart
//
// Main dashboard with bottom navigation for accessible tab-based UI
// Three tabs: Books (library), Scan, Settings
//
// Accessibility features:
// - Full TalkBack/VoiceOver support
// - Large touch targets (48x48 minimum)
// - High contrast colors
// - Proper semantic labels
// - Live region announcements for state changes
// - RTL support for Persian text

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_screen.dart';
import 'scan_tab.dart';
import 'settings_tab.dart';
import '../../../features/l10n/app_localizations.dart';

enum DashboardTab {
  books(Icons.library_books, 'booksTab', 'booksTab'),
  scan(Icons.document_scanner, 'scanTab', 'scanTab'),
  settings(Icons.settings, 'profileTab', 'settings');

  final IconData icon;
  final String labelKey;
  final String semanticLabelKey;

  const DashboardTab(this.icon, this.labelKey, this.semanticLabelKey);
}

class MainDashboard extends ConsumerStatefulWidget {
  const MainDashboard({super.key});

  @override
  ConsumerState<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends ConsumerState<MainDashboard> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final localizations = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'justOCR',
          textDirection: localizations.language.textDirection,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: Stack(
        children: [
          // PageView for swipeable tabs
          PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            children: const [
              LibraryScreen(),
              ScanTab(),
              SettingsTab(),
            ],
          ),

          // Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Semantics(
                  label: localizations.accessibilityLabel,
                  explicitChildNodes: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      DashboardTab.values.length,
                      (index) => _buildNavItem(
                        tab: DashboardTab.values[index],
                        isSelected: _currentIndex == index,
                        onTap: () => _onTabTapped(index),
                        localizations: localizations,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required DashboardTab tab,
    required bool isSelected,
    required VoidCallback onTap,
    required AppLocalizations localizations,
  }) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Expanded(
      child: Semantics(
        button: true,
        selected: isSelected,
        label: localizations.getString(tab.semanticLabelKey),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with proper size and contrast
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    tab.icon,
                    size: 28,
                    color: isSelected
                        ? colors.onPrimaryContainer
                        : colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                // Label with proper text scaling
                Text(
                  localizations.getString(tab.labelKey),
                  textDirection: localizations.language.textDirection,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected
                        ? colors.primary
                        : colors.onSurface.withOpacity(0.7),
                    fontSize: 12,
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
