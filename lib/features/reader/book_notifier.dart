// lib/features/reader/book_notifier.dart
//
// All business logic for document import and reader navigation lives here.
// Zero Flutter widget code, zero BuildContext, zero showDialog calls.
// The screen simply watches bookNotifierProvider and reacts to state changes.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart'; // debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'book_state.dart'; // BookState, BookEmpty, BookImporting, BookReading, BookError, splitIntoParagraphs

// ---------------------------------------------------------------------------
// ProgressCallback
//
// The OCR service calls this typedef to report pipeline stage changes.
// Using a plain function type keeps the service layer completely decoupled
// from Flutter's widget system — no ValueNotifier is ever passed into a
// service class in this codebase.
//
// [message]  : a human-readable Persian string describing the current stage,
//              e.g. "در حال برش صفحه ۳ از ۱۲..."
// [progress] : 0.0–1.0 for deterministic stages (page-by-page upload),
//              null for indeterminate stages (initial file validation).
// ---------------------------------------------------------------------------
typedef ProgressCallback = void Function(String message, double? progress);

// ---------------------------------------------------------------------------
// Abstract service contracts
//
// These are the interfaces your concrete service classes must implement.
// BookNotifier depends only on these abstractions — never on concrete types —
// which makes the notifier fully testable with mock implementations.
// ---------------------------------------------------------------------------

/// Responsible for opening the native file picker dialog and returning
/// the selected file. Returns null if the user cancels the picker.
abstract class FileImportService {
  Future<File?> pickFile();
}

/// Responsible for processing a file through the full OCR pipeline and
/// returning a list of extracted text strings, one entry per page.
/// Must call [onProgress] at every meaningful pipeline stage transition.
abstract class OcrService {
  Future<List<String>> extractPages(
    File file, {
    required ProgressCallback onProgress,
  });
}

// ---------------------------------------------------------------------------
// SharedPreferences keys — one place to change if keys are ever renamed.
// ---------------------------------------------------------------------------
const String _kPageIndexKey      = 'justocr_last_page_index';
const String _kParagraphIndexKey = 'justocr_last_paragraph_index';

// Delay after the last navigation tap before writing position to disk.
// Prevents hammering SharedPreferences when the user holds a nav button.
// Result: exactly one disk write fires 600ms after tapping stops.
const Duration _kPersistenceDebounce = Duration(milliseconds: 600);

// ---------------------------------------------------------------------------
// BookNotifier
// ---------------------------------------------------------------------------
class BookNotifier extends StateNotifier<BookState> {
  BookNotifier({
    required FileImportService fileImportService,
    required OcrService ocrService,
    required SharedPreferences prefs,
  })  : _fileImportService = fileImportService,
        _ocrService = ocrService,
        _prefs = prefs,
        super(const BookEmpty());

  final FileImportService _fileImportService;
  final OcrService _ocrService;
  final SharedPreferences _prefs;

  // Holds the pending debounced write timer. Cancelled on dispose.
  Timer? _persistenceDebounceTimer;

  // -------------------------------------------------------------------------
  // Import pipeline
  // -------------------------------------------------------------------------

  /// Opens the file picker, runs the full OCR pipeline, and transitions
  /// the state from BookEmpty → BookImporting → BookReading (or BookError).
  ///
  /// Every stage update calls [_ocrService.extractPages] onProgress callback,
  /// which sets a new BookImporting state. The screen renders this directly
  /// as an inline progress view — no dialog is created at any point.
  Future<void> importDocument() async {
    // Guard against re-entry: do not start a new import while one is running.
    if (state is BookImporting) return;

    final File? file = await _fileImportService.pickFile();

    // User dismissed the picker without selecting a file — stay in current
    // state. Do not push BookEmpty if we were already in BookReading.
    if (file == null) return;

    state = const BookImporting(
      statusMessage: 'در حال آمادهسازی فایل...',
      progress: null, // indeterminate until we know total page count
    );

    try {
      final List<String> pages = await _ocrService.extractPages(
        file,
        onProgress: (String message, double? progress) {
          // Pushing a new BookImporting on every callback is intentional.
          // The screen's Semantics liveRegion will announce each message
          // to screen readers without any extra widget-layer plumbing.
          state = BookImporting(statusMessage: message, progress: progress);
        },
      );

      if (pages.isEmpty) {
        state = const BookError(
          'هیچ متنی از سند استخراج نشد. لطفاً یک فایل معتبر انتخاب کنید.',
        );
        return;
      }

      // Attempt to restore the last reading position saved from a previous
      // session. We validate both indices against the new document's bounds
      // to safely handle the case where the user imports a different document.
      final int savedPage      = _prefs.getInt(_kPageIndexKey) ?? 0;
      final int savedParagraph = _prefs.getInt(_kParagraphIndexKey) ?? 0;

      final int restoredPage =
          (savedPage >= 0 && savedPage < pages.length) ? savedPage : 0;

      final List<String> paragraphsOnRestoredPage =
          splitIntoParagraphs(pages[restoredPage]);

      final int restoredParagraph =
          (savedParagraph >= 0 &&
                  savedParagraph < paragraphsOnRestoredPage.length)
              ? savedParagraph
              : 0;

      state = BookReading(
        pages: pages,
        pageIndex: restoredPage,
        paragraphIndex: restoredParagraph,
      );
    } catch (e, stackTrace) {
      // Surface every pipeline exception as BookError so the user always
      // sees an actionable message rather than a frozen progress screen.
      debugPrint('[BookNotifier] importDocument failed: $e');
      debugPrint('[BookNotifier] Stack trace:\n$stackTrace');
      state = BookError('خطا در پردازش سند: ${e.toString()}');
    }
  }

  // -------------------------------------------------------------------------
  // Page navigation
  // -------------------------------------------------------------------------

  /// Advances to the next page. Paragraph focus resets to 0 on the new page.
  /// No-op if already on the last page or state is not BookReading.
  void nextPage() {
    final BookState current = state;
    if (current is! BookReading) return;
    if (!current.hasNextPage) return;

    final BookReading next = current.copyWith(
      pageIndex: current.pageIndex + 1,
      paragraphIndex: 0,
    );
    state = next;
    _schedulePersistence(next);
  }

  /// Returns to the previous page. Paragraph focus resets to 0 on the new page.
  /// No-op if already on the first page or state is not BookReading.
  void previousPage() {
    final BookState current = state;
    if (current is! BookReading) return;
    if (!current.hasPreviousPage) return;

    final BookReading next = current.copyWith(
      pageIndex: current.pageIndex - 1,
      paragraphIndex: 0,
    );
    state = next;
    _schedulePersistence(next);
  }

  // -------------------------------------------------------------------------
  // Paragraph navigation
  // -------------------------------------------------------------------------

  /// Advances to the next paragraph.
  ///
  /// If the focused paragraph is not the last one on the current page,
  /// increments paragraphIndex by 1 within the same page.
  ///
  /// If the focused paragraph IS the last one on the current page and there
  /// is a next page available, rolls over to paragraph 0 of the next page.
  ///
  /// No-op if there is no next paragraph anywhere and no next page.
  void nextParagraph() {
    final BookState current = state;
    if (current is! BookReading) return;
    if (!current.hasNextParagraph) return;

    final int lastIndexOnCurrentPage = current.currentParagraphs.length - 1;

    final BookReading next;

    if (current.paragraphIndex < lastIndexOnCurrentPage) {
      // Normal case: advance within the same page.
      next = current.copyWith(
        paragraphIndex: current.paragraphIndex + 1,
      );
    } else {
      // Roll-over case: current paragraph is the last on this page.
      // Jump to the first paragraph of the next page.
      next = current.copyWith(
        pageIndex: current.pageIndex + 1,
        paragraphIndex: 0,
      );
    }

    state = next;
    _schedulePersistence(next);
  }

  /// Returns to the previous paragraph.
  ///
  /// If the focused paragraph is not the first one on the current page,
  /// decrements paragraphIndex by 1 within the same page.
  ///
  /// If the focused paragraph IS the first one on the current page and there
  /// is a previous page available, rolls back to the LAST paragraph of the
  /// previous page. This mirrors the natural reading flow: going back from
  /// the top of a page lands you at the bottom of the page before it.
  ///
  /// No-op if on the very first paragraph of the very first page.
  void previousParagraph() {
    final BookState current = state;
    if (current is! BookReading) return;
    if (!current.hasPreviousParagraph) return;

    final BookReading next;

    if (current.paragraphIndex > 0) {
      // Normal case: go back within the same page.
      next = current.copyWith(
        paragraphIndex: current.paragraphIndex - 1,
      );
    } else {
      // Roll-back case: current paragraph is the first on this page.
      // Jump to the LAST paragraph of the previous page.
      final int previousPageIndex = current.pageIndex - 1;
      final int lastParagraphOfPreviousPage =
          splitIntoParagraphs(current.pages[previousPageIndex]).length - 1;

      next = current.copyWith(
        pageIndex: previousPageIndex,
        paragraphIndex: lastParagraphOfPreviousPage,
      );
    }

    state = next;
    _schedulePersistence(next);
  }

  // -------------------------------------------------------------------------
  // Reset
  // -------------------------------------------------------------------------

  /// Clears all state back to BookEmpty.
  /// Called from the error screen's retry button and from any
  /// "import new document" action that needs to start from a clean slate.
  void reset() {
    _persistenceDebounceTimer?.cancel();
    state = const BookEmpty();
  }

  // -------------------------------------------------------------------------
  // Persistence
  // -------------------------------------------------------------------------

  /// Schedules a debounced write of [reading]'s position to SharedPreferences.
  ///
  /// Any pending write is cancelled first. The actual disk write fires only
  /// after [_kPersistenceDebounce] has elapsed without another navigation tap.
  /// This collapses a burst of rapid taps into a single I/O operation.
  void _schedulePersistence(BookReading reading) {
    _persistenceDebounceTimer?.cancel();
    _persistenceDebounceTimer = Timer(_kPersistenceDebounce, () {
      _prefs.setInt(_kPageIndexKey, reading.pageIndex);
      _prefs.setInt(_kParagraphIndexKey, reading.paragraphIndex);
    });
  }

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void dispose() {
    // Cancel any pending debounce timer to avoid writing to a SharedPreferences
    // instance after the notifier has been torn down.
    _persistenceDebounceTimer?.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Providers
//
// fileImportServiceProvider, ocrServiceProvider, and sharedPreferencesProvider
// are intentionally declared as unimplemented stubs. You MUST override all
// three of them inside the ProviderScope in main.dart by passing your concrete
// implementations. Forgetting to override any one will throw a clear
// AssertionError at startup with an explanatory message — never a null crash.
// ---------------------------------------------------------------------------

/// Provide your concrete FileImportService implementation via ProviderScope.
final Provider<FileImportService> fileImportServiceProvider =
    Provider<FileImportService>((Ref ref) {
  throw AssertionError(
    'fileImportServiceProvider has not been overridden in ProviderScope. '
    'See main.dart — pass your concrete FileImportService.',
  );
});

/// Provide your concrete OcrService implementation via ProviderScope.
final Provider<OcrService> ocrServiceProvider =
    Provider<OcrService>((Ref ref) {
  throw AssertionError(
    'ocrServiceProvider has not been overridden in ProviderScope. '
    'See main.dart — pass your concrete OcrService.',
  );
});

/// SharedPreferences must be initialised in main() before runApp() and then
/// injected here via ProviderScope overrides.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref ref) {
  throw AssertionError(
    'sharedPreferencesProvider has not been overridden in ProviderScope. '
    'Call SharedPreferences.getInstance() in main() and inject the result.',
  );
});

/// The single provider the entire UI tree watches.
/// Declared at the top level — accessible from any ConsumerWidget without
/// passing it through constructor chains.
final StateNotifierProvider<BookNotifier, BookState> bookNotifierProvider =
    StateNotifierProvider<BookNotifier, BookState>((Ref ref) {
  return BookNotifier(
    fileImportService: ref.watch(fileImportServiceProvider),
    ocrService:        ref.watch(ocrServiceProvider),
    prefs:             ref.watch(sharedPreferencesProvider),
  );
});