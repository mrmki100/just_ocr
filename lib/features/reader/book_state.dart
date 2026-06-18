// lib/features/reader/book_state.dart
//
// Single source of truth for every possible UI state of the reader.
// The screen does nothing except react to which subtype is currently active.
// Zero business logic lives in widgets — it all lives here and in BookNotifier.

import 'package:flutter/foundation.dart'; // for listEquals

// ---------------------------------------------------------------------------
// Paragraph splitter — top-level so BookReading can call it from a getter
// and BookNotifier can call it when computing cross-page rollover boundaries.
//
// Gemini 2.5 Flash formats OCR output with double-newlines between paragraphs
// when the source document has clear visual separation. However, densely
// typeset Persian books sometimes produce single-newline output.
// We try the more meaningful split first, then fall back gracefully.
// ---------------------------------------------------------------------------
List<String> splitIntoParagraphs(String pageText) {
  if (pageText.trim().isEmpty) return [''];

  // Primary: one or more blank lines separating paragraphs.
  final List<String> byBlankLine = pageText
      .split(RegExp(r'\n\s*\n+'))
      .map((String p) => p.trim())
      .where((String p) => p.isNotEmpty)
      .toList();

  // If we got more than one chunk the document had real paragraph breaks.
  if (byBlankLine.length > 1) return byBlankLine;

  // Fallback: treat every non-empty line as its own navigable unit.
  final List<String> byLine = pageText
      .split('\n')
      .map((String p) => p.trim())
      .where((String p) => p.isNotEmpty)
      .toList();

  // Last resort: the whole page is one paragraph.
  return byLine.isEmpty ? [pageText.trim()] : byLine;
}

// ---------------------------------------------------------------------------
// Sealed class root — Dart 3 exhaustive switching in the screen is enforced
// at compile time. Adding a new subtype here causes every switch site to
// produce a compile error until it is handled. No silent UI gaps ever.
// ---------------------------------------------------------------------------
sealed class BookState {
  const BookState();
}

// ---------------------------------------------------------------------------
// BookEmpty — no document loaded. Screen shows import call-to-action.
// ---------------------------------------------------------------------------
final class BookEmpty extends BookState {
  const BookEmpty();
}

// ---------------------------------------------------------------------------
// BookImporting — file has been selected; pipeline is running.
// The screen renders this directly — there is NO dialog, NO overlay,
// NO showDialog call anywhere in the app. Progress is just state.
//
// [statusMessage] is a human-readable Persian string set by the notifier
// as each pipeline stage fires, e.g. "در حال برش صفحه ۳ از ۱۲...".
//
// [progress] is 0.0–1.0 when a deterministic stage is running (page upload)
// or null when the stage is indeterminate (initial file validation).
// ---------------------------------------------------------------------------
final class BookImporting extends BookState {
  final String statusMessage;
  final double? progress;

  const BookImporting({
    required this.statusMessage,
    this.progress,
  });
}

// ---------------------------------------------------------------------------
// BookReading — extraction succeeded. Screen shows text and nav controls.
//
// [pages]          : every page extracted by Gemini, index-aligned.
// [pageIndex]      : which page is currently visible, 0-based.
// [paragraphIndex] : which paragraph within the current page is focused,
//                    used for paragraph-level navigation highlighting.
//
// All boundary guards live here so the notifier and the UI both read from
// one place. The "can I navigate?" question is never answered twice.
// ---------------------------------------------------------------------------
final class BookReading extends BookState {
  final List<String> pages;
  final int pageIndex;
  final int paragraphIndex;

  const BookReading({
    required this.pages,
    required this.pageIndex,
    required this.paragraphIndex,
  });

  // Splits the currently visible page into its navigable paragraphs.
  // Called by the notifier for cross-page boundary calculations and by
  // the UI widget to highlight the active paragraph.
  List<String> get currentParagraphs => splitIntoParagraphs(pages[pageIndex]);

  // ------ Page boundary guards ------

  /// True when there is at least one page after the current one.
  bool get hasNextPage => pageIndex < pages.length - 1;

  /// True when there is at least one page before the current one.
  bool get hasPreviousPage => pageIndex > 0;

  // ------ Paragraph boundary guards (cross-page aware) ------

  /// True when the user can advance: either there is a next paragraph on
  /// this page, or there is a next page to roll over into.
  bool get hasNextParagraph =>
      paragraphIndex < currentParagraphs.length - 1 || hasNextPage;

  /// True when the user can go back: either there is a previous paragraph
  /// on this page, or there is a previous page to roll back into.
  bool get hasPreviousParagraph => paragraphIndex > 0 || hasPreviousPage;

  // ------ Convenience read ------

  /// Total number of pages in the loaded document.
  int get totalPages => pages.length;

  /// The text of the paragraph currently in focus. Safe to call at any time.
  String get currentParagraphText {
    final List<String> paras = currentParagraphs;
    if (paragraphIndex >= paras.length) return paras.last;
    return paras[paragraphIndex];
  }

  // ------ Immutable update ------

  /// Returns a new BookReading with only the changed fields replaced.
  /// Pages list is never copied — it is shared by reference intentionally
  /// since it is immutable content extracted from the document.
  BookReading copyWith({int? pageIndex, int? paragraphIndex}) {
    return BookReading(
      pages: pages,
      pageIndex: pageIndex ?? this.pageIndex,
      paragraphIndex: paragraphIndex ?? this.paragraphIndex,
    );
  }

  // ------ Value equality ------
  // Riverpod's StateNotifier will not re-render the widget tree if the
  // new state is equal to the old state, so correct equality is important
  // for preventing unnecessary rebuilds during rapid navigation taps.

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BookReading &&
        listEquals(other.pages, pages) &&
        other.pageIndex == pageIndex &&
        other.paragraphIndex == paragraphIndex;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(pages), pageIndex, paragraphIndex);
}

// ---------------------------------------------------------------------------
// BookError — pipeline threw or returned empty content.
// Screen shows the message and a retry button that resets to BookEmpty.
// ---------------------------------------------------------------------------
final class BookError extends BookState {
  final String message;
  const BookError(this.message);
}