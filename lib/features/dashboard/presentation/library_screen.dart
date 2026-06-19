// lib/features/dashboard/library_screen.dart
//
// The single screen of the application.
// This file contains ZERO business logic, ZERO showDialog calls, and
// ZERO orchestration code. It watches bookNotifierProvider and rebuilds
// whichever sub-view matches the current BookState subtype.
//
// Sub-widgets defined in this file (all private, prefixed with _):
//   _EmptyView        — no document loaded, shows call-to-action
//   _ImportingView    — OCR pipeline running, inline progress (no dialog)
//   _ReaderView       — extracted text with paragraph highlighting + auto-scroll
//   _ParagraphTile    — single focusable paragraph unit
//   _ErrorView        — pipeline failure with retry action
//   _ReaderControls   — bottom bar with 4 navigation buttons
//   _NavButton        — accessible 48×48 icon button

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:justcr/features/reader/book_notifier.dart';
import 'package:justcr/features/reader/book_state.dart';

// ---------------------------------------------------------------------------
// LibraryScreen
// ---------------------------------------------------------------------------
class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookState state = ref.watch(bookNotifierProvider);
    final BookNotifier notifier = ref.read(bookNotifierProvider.notifier);
    final bool isImporting = state is BookImporting;

    // Build the body using an exhaustive sealed-class switch.
    // The Dart 3 compiler enforces that every BookState subtype is handled.
    // If a new subtype is added to book_state.dart, this switch will refuse
    // to compile until the new case is covered — no silent blank screens ever.
    final Widget body;
    switch (state) {
      case BookEmpty():
        body = const _EmptyView();
      case BookImporting():
        body = _ImportingView(state: state);
      case BookReading():
        body = _ReaderView(state: state);
      case BookError():
        body = _ErrorView(
          state: state,
          onRetry: notifier.reset,
        );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'justOCR',
          textDirection: TextDirection.rtl,
        ),
        actions: [
          // Import button lives in the AppBar so it is reachable in ALL
          // states, including BookReading (when the user wants a new doc).
          // It is disabled — not removed — during active importing so that
          // screen readers can still discover it and hear it is inactive.
          Semantics(
            button: true,
            label: 'انتخاب سند جدید',
            enabled: !isImporting,
            child: IconButton(
              icon: const Icon(Icons.file_open_outlined),
              tooltip: 'انتخاب سند جدید',
              onPressed: isImporting ? null : notifier.importDocument,
            ),
          ),
        ],
      ),
      // The reader controls BottomAppBar is genuinely absent from the
      // widget tree in non-reading states — not hidden, not opacity-zeroed.
      // This prevents screen readers from discovering phantom buttons.
      bottomNavigationBar: state is BookReading
          ? _ReaderControls(state: state as BookReading)
          : null,
      // FAB only in BookEmpty as the primary call-to-action.
      floatingActionButton: state is BookEmpty
          ? Semantics(
              button: true,
              label: 'انتخاب سند برای پردازش',
              child: FloatingActionButton.extended(
                onPressed: notifier.importDocument,
                icon: const Icon(Icons.add),
                label: const Text(
                  'انتخاب سند',
                  textDirection: TextDirection.rtl,
                ),
              ),
            )
          : null,
      body: body,
    );
  }
}

// ---------------------------------------------------------------------------
// _EmptyView
//
// Shown when no document has been loaded. The FAB on the parent Scaffold
// provides the import action; this view supplies visual and semantic context.
// ---------------------------------------------------------------------------
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative icon — excluded from the a11y tree because the
            // Text widgets below carry all the necessary semantic content.
            ExcludeSemantics(
              child: Icon(
                Icons.menu_book_outlined,
                size: 88,
                color: theme.colorScheme.onSurface.withOpacity(0.22),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'هیچ سندی بارگذاری نشده است',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Text(
              'برای شروع، دکمه «انتخاب سند» را لمس کنید',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ImportingView
//
// Replaces the old showDialog approach entirely. Progress is rendered inline
// in the main body. The Semantics liveRegion on the status Text causes screen
// readers to announce each stage update automatically as the BookNotifier
// pushes successive BookImporting states — zero widget-layer plumbing needed.
// ---------------------------------------------------------------------------
class _ImportingView extends StatelessWidget {
  final BookImporting state;
  const _ImportingView({required this.state});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // value: null  →  indeterminate (animated sweep)
            // value: 0–1   →  determinate (fills as pages complete)
            LinearProgressIndicator(
              value: state.progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 24),
            // ── CRITICAL ACCESSIBILITY: liveRegion: true ──────────────────
            // Every time this widget rebuilds with a new statusMessage the
            // OS accessibility service will read the new text aloud without
            // the user needing to navigate focus to this node manually.
            // This is the only flag needed to replace a progress dialog for
            // screen reader users.
            Semantics(
              liveRegion: true,
              child: Text(
                state.statusMessage,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
            ),
            const SizedBox(height: 16),
            // Numeric percentage — only shown during deterministic stages.
            if (state.progress != null)
              Text(
                '${(state.progress! * 100).toStringAsFixed(0)}٪',
                textDirection: TextDirection.rtl,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ReaderView
//
// Renders all paragraphs of the current page in a scrollable column.
// The focused paragraph is highlighted with a tinted background and a
// right-side border (RTL reading-start edge).
//
// Auto-scroll: a GlobalKey is assigned to each paragraph widget. When
// paragraphIndex or pageIndex changes, Scrollable.ensureVisible is called
// via a PostFrameCallback so the focused paragraph stays in view.
//
// StatefulWidget (not ConsumerWidget) — scroll state and GlobalKeys are
// local UI concerns. The BookReading state is received as a parameter from
// LibraryScreen which is already watching the provider.
// ---------------------------------------------------------------------------
class _ReaderView extends StatefulWidget {
  final BookReading state;
  const _ReaderView({required this.state});

  @override
  State<_ReaderView> createState() => _ReaderViewState();
}

class _ReaderViewState extends State<_ReaderView> {
  final ScrollController _scrollController = ScrollController();

  // One stable GlobalKey per paragraph on the currently displayed page.
  // Keys are regenerated only when the page changes or paragraph count
  // changes — regenerating unnecessarily would create fresh keys that are
  // not yet attached to the tree, breaking ensureVisible.
  late List<GlobalKey> _paragraphKeys;
  late int _trackedPageIndex;
  late int _trackedParagraphCount;

  @override
  void initState() {
    super.initState();
    final List<String> paragraphs = widget.state.currentParagraphs;
    _initKeys(paragraphs.length);

    // If restoring from a saved session at a non-zero paragraph, scroll
    // there after the first frame is drawn.
    if (widget.state.paragraphIndex > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentParagraph();
      });
    }
  }

  @override
  void didUpdateWidget(_ReaderView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final List<String> paragraphs = widget.state.currentParagraphs;

    // Regenerate keys when page or paragraph count changes.
    if (widget.state.pageIndex != _trackedPageIndex ||
        paragraphs.length != _trackedParagraphCount) {
      _initKeys(paragraphs.length);
    }

    // Schedule auto-scroll on any navigation that changes position.
    final bool pageChanged =
        oldWidget.state.pageIndex != widget.state.pageIndex;
    final bool paragraphChanged =
        oldWidget.state.paragraphIndex != widget.state.paragraphIndex;

    if (pageChanged || paragraphChanged) {
      // PostFrameCallback ensures paragraph widgets have been built and
      // their GlobalKeys attached to the element tree before we resolve
      // their BuildContexts for ensureVisible.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentParagraph();
      });
    }
  }

  /// Creates a fresh list of GlobalKeys for [count] paragraphs and
  /// records the page index and count used for future change detection.
  void _initKeys(int count) {
    _paragraphKeys = List.generate(count, (_) => GlobalKey());
    _trackedPageIndex = widget.state.pageIndex;
    _trackedParagraphCount = count;
  }

  /// Scrolls the currently focused paragraph widget into the viewport.
  ///
  /// alignment: 0.2 places the target 20% from the top of the viewport
  /// so the user can see text above it for reading context.
  void _scrollToCurrentParagraph() {
    if (!mounted) return;
    final int targetIndex = widget.state.paragraphIndex;
    if (targetIndex >= _paragraphKeys.length) return;
    final BuildContext? ctx = _paragraphKeys[targetIndex].currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      alignment: 0.2,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> paragraphs = widget.state.currentParagraphs;

    return SingleChildScrollView(
      controller: _scrollController,
      // Bottom padding gives room so the last paragraph is not obscured
      // by the BottomAppBar navigation controls.
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Page position indicator — purely informational, not interactive.
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'صفحه ${widget.state.pageIndex + 1} از ${widget.state.totalPages}',
              textDirection: TextDirection.rtl,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.50),
              ),
            ),
          ),
          // Render each paragraph with its stable GlobalKey.
          // List.generate is used instead of .asMap().entries.map() to keep
          // the key assignment free of intermediate Entry allocations.
          ...List.generate(paragraphs.length, (int index) {
            return _ParagraphTile(
              key: _paragraphKeys[index],
              text: paragraphs[index],
              isFocused: index == widget.state.paragraphIndex,
              paragraphNumber: index + 1,
              totalParagraphs: paragraphs.length,
            );
          }),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ParagraphTile
//
// A single paragraph rendered with animated focus highlighting.
// The right-side border marks the RTL reading-start edge.
// The Semantics label includes paragraph position and focused state so that
// screen readers announce the full context without the user navigating
// into the text content first.
// ---------------------------------------------------------------------------
class _ParagraphTile extends StatelessWidget {
  final String text;
  final bool isFocused;
  final int paragraphNumber;
  final int totalParagraphs;

  const _ParagraphTile({
    required super.key,
    required this.text,
    required this.isFocused,
    required this.paragraphNumber,
    required this.totalParagraphs,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Semantics(
      // The label gives the screen reader full context about this paragraph's
      // position in the page and whether it is the currently focused unit.
      label: 'بند $paragraphNumber از $totalParagraphs'
          '${isFocused ? "، بند فعال" : ""}',
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
        decoration: BoxDecoration(
          color: isFocused
              ? colors.primaryContainer.withOpacity(0.50)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          // Right border = reading-start marker for RTL text.
          border: isFocused
              ? Border(
                  right: BorderSide(
                    color: colors.primary,
                    width: 4,
                  ),
                )
              : null,
        ),
        child: SelectableText(
          text,
          textDirection: TextDirection.rtl,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.80,
            fontWeight:
                isFocused ? FontWeight.w600 : FontWeight.normal,
            color: isFocused ? colors.onPrimaryContainer : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ErrorView
//
// Shown when the OCR pipeline throws or returns empty content.
// The retry button calls notifier.reset() which transitions back to
// BookEmpty, letting the user attempt a fresh import.
// ---------------------------------------------------------------------------
class _ErrorView extends StatelessWidget {
  final BookError state;
  final VoidCallback onRetry;

  const _ErrorView({
    required this.state,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Decorative icon — the Text widget below carries the a11y label.
            ExcludeSemantics(
              child: Icon(
                Icons.error_outline_rounded,
                size: 72,
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              state.message,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 28),
            Semantics(
              button: true,
              label: 'تلاش مجدد — بازگشت به صفحه اصلی',
              child: ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'تلاش مجدد',
                  textDirection: TextDirection.rtl,
                ),
                // Enforces WCAG 2.5.5 minimum touch target height.
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(120, 48),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _ReaderControls
//
// The BottomAppBar navigation bar shown only in BookReading state.
// Four buttons: previous page, previous paragraph, next paragraph, next page.
//
// Button enabled/disabled state is driven by BookReading's boundary guards
// (hasPreviousPage, hasPreviousParagraph, etc.) which are already computed
// in book_state.dart. A button with onPressed: null is automatically
// rendered as disabled — Semantics.enabled: false ensures screen readers
// announce each inactive button as "غیرفعال" rather than skipping it.
//
// ConsumerWidget because it needs ref.read(bookNotifierProvider.notifier)
// to wire up the button callbacks.
// ---------------------------------------------------------------------------
class _ReaderControls extends ConsumerWidget {
  final BookReading state;
  const _ReaderControls({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BookNotifier notifier = ref.read(bookNotifierProvider.notifier);

    return BottomAppBar(
      padding: EdgeInsets.zero,
      child: Semantics(
        // Declare this row as a navigation landmark so screen reader users
        // can jump to it directly with a single swipe gesture.
        label: 'کنترل‌های ناوبری',
        explicitChildNodes: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _NavButton(
              icon: Icons.skip_previous_rounded,
              label: 'صفحه قبل',
              onPressed:
                  state.hasPreviousPage ? notifier.previousPage : null,
            ),
            _NavButton(
              icon: Icons.navigate_before_rounded,
              label: 'بند قبل',
              onPressed: state.hasPreviousParagraph
                  ? notifier.previousParagraph
                  : null,
            ),
            _NavButton(
              icon: Icons.navigate_next_rounded,
              label: 'بند بعد',
              onPressed:
                  state.hasNextParagraph ? notifier.nextParagraph : null,
            ),
            _NavButton(
              icon: Icons.skip_next_rounded,
              label: 'صفحه بعد',
              onPressed: state.hasNextPage ? notifier.nextPage : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _NavButton
//
// A single accessible navigation icon button.
//
// Semantics.enabled: false when onPressed is null tells screen readers to
// announce the button as inactive rather than silently omitting it from the
// accessibility tree. The user always knows all four controls exist — they
// just hear which ones are currently available.
//
// IconButton.styleFrom minimumSize enforces the 48×48 logical pixel minimum
// required by WCAG 2.5.5 (AAA) and Android Material guidance.
// ---------------------------------------------------------------------------
class _NavButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      enabled: onPressed != null,
      child: IconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: label,
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
        ),
      ),
    );
  }
}