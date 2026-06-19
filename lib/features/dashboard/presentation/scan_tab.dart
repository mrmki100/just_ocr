// lib/features/dashboard/presentation/scan_tab.dart
//
// Scan tab for importing and processing new documents
// Provides accessible file selection and OCR progress feedback
//
// Accessibility features:
// - Large touch targets
// - Clear status announcements via live regions
// - Full RTL support
// - High contrast UI

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:just_ocr/features/reader/book_notifier.dart';
import 'package:just_ocr/features/reader/book_state.dart';

class ScanTab extends ConsumerWidget {
  const ScanTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookState state = ref.watch(bookNotifierProvider);
    final BookNotifier notifier = ref.read(bookNotifierProvider.notifier);

    // Determine current scan state
    final bool isImporting = state is BookImporting;
    final bool hasDocument = state is BookReading;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with instructions
          Semantics(
            header: true,
            child: Text(
              'اسکن سند جدید',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'یک فایل PDF، تصویر (JPG/PNG) یا EPUB انتخاب کنید تا متن آن استخراج شود.',
            textDirection: TextDirection.rtl,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.7),
                ),
          ),
          const SizedBox(height: 32),

          // Main action button
          if (!isImporting && !hasDocument) ...[
            _buildScanButton(
              context,
              onPressed: notifier.importDocument,
            ),
          ],

          // Progress indicator during import
          if (isImporting) ...[
            Expanded(
              child: Center(
                child: _buildProgressView(state as BookImporting),
              ),
            ),
          ],

          // Success state with option to scan another
          if (hasDocument) ...[
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 72,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'سند با موفقیت پردازش شد!',
                      textDirection: TextDirection.rtl,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'برای مشاهده به تب کتاب‌ها بروید یا سند دیگری اسکن کنید.',
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: notifier.reset,
                      icon: const Icon(Icons.add),
                      label: const Text(
                        'اسکن سند دیگر',
                        textDirection: TextDirection.rtl,
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(200, 56),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Supported formats info
          const SizedBox(height: 32),
          _buildSupportedFormatsCard(context),
        ],
      ),
    );
  }

  Widget _buildScanButton(BuildContext context, {VoidCallback? onPressed}) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Center(
      child: Semantics(
        button: true,
        label: 'انتخاب فایل برای اسکن',
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.primary,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.document_scanner_rounded,
                  size: 64,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(height: 16),
                Text(
                  'لمس برای اسکن',
                  textDirection: TextDirection.rtl,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressView(BookImporting state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular progress indicator
          CircularProgressIndicator(
            value: state.progress,
            strokeWidth: 6,
          ),
          const SizedBox(height: 32),
          // Status message with live region for screen readers
          Semantics(
            liveRegion: true,
            child: Text(
              state.statusMessage,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (state.progress != null) ...[
            const SizedBox(height: 16),
            Text(
              '${(state.progress! * 100).toStringAsFixed(0)}٪ تکمیل شده',
              textDirection: TextDirection.rtl,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSupportedFormatsCard(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: colors.surfaceVariant.withOpacity(0.5),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'فرمت‌های پشتیبانی شده:',
                  textDirection: TextDirection.rtl,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              textDirection: TextDirection.rtl,
              children: [
                _formatChip(context, 'PDF', 'فایل‌های پی‌دی‌اف'),
                _formatChip(context, 'JPG/PNG', 'تصاویر'),
                _formatChip(context, 'EPUB', 'کتاب‌های الکترونیکی'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _formatChip(BuildContext context, String label, String description) {
    return Semantics(
      label: '$label - $description',
      child: Chip(
        label: Text(
          label,
          textDirection: TextDirection.rtl,
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}
