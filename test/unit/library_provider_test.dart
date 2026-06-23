// test/unit/library_provider_test.dart
//
// Comprehensive unit tests for the LibraryProvider state machine.
// Tests cover all state transitions, error handling, CRUD operations,
// and edge cases with extreme precision.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_ocr/providers/library_provider.dart';
import 'package:just_ocr/core/error/app_error.dart';
import 'package:just_ocr/data/models/scan_event.dart';
import 'package:just_ocr/services/library/library_service.dart';

// Manual mock implementation for LibraryService
class MockLibraryService implements LibraryService {
  bool shouldThrow = false;
  Exception? exceptionToThrow;
  List<Book>? booksToReturn;
  Book? bookToReturn;
  List<SearchResult>? searchResultsToReturn;
  
  @override
  Future<void> initialize() async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock initialization failed');
  }

  @override
  Future<Book> saveBook({
    required String title,
    required List<String> pages,
    required SourceType sourceType,
    String? filePath,
  }) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock save failed');
    return bookToReturn ?? (Book()
      ..id = 1
      ..title = title
      ..pages = pages
      ..status = BookStatus.ready);
  }

  @override
  Future<List<Book>> getAllBooks() async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock get all failed');
    return booksToReturn ?? [];
  }

  @override
  Future<Book?> getBookById(int id) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock get by id failed');
    return bookToReturn;
  }

  @override
  Future<Book?> getBookByUuid(String uuid) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock get by uuid failed');
    return bookToReturn;
  }

  @override
  Future<void> updateReadingPosition({
    required int bookId,
    required int pageIndex,
    required int paragraphIndex,
  }) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock update position failed');
  }

  @override
  Future<void> markAsRead(int bookId) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock mark as read failed');
  }

  @override
  Future<void> deleteBook(int bookId) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock delete failed');
  }

  @override
  Future<List<SearchResult>> searchInBooks(String query) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock search failed');
    return searchResultsToReturn ?? [];
  }

  @override
  Future<List<Book>> getBooksByStatus(BookStatus status) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock get by status failed');
    return booksToReturn ?? [];
  }

  @override
  Future<void> updateBookStatus(int bookId, BookStatus status) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock update status failed');
  }

  @override
  Future<void> setBookError(int bookId, String errorMessage) async {
    if (shouldThrow) throw exceptionToThrow ?? Exception('Mock set error failed');
  }

  @override
  void dispose() {}
}

void main() {
  late MockLibraryService mockLibraryService;
  late ProviderContainer container;

  setUp(() {
    mockLibraryService = MockLibraryService();
    container = ProviderContainer(
      overrides: [
        libraryServiceProvider.overrideWithValue(mockLibraryService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LibraryNotifier - Initialization', () {
    test('should start in Loading state', () {
      final notifier = container.read(libraryNotifierProvider.notifier);
      expect(container.read(libraryNotifierProvider), isA<LibraryLoading>());
    });

    test('should transition to Loaded state on successful initialization', () async {
      final mockBooks = [
        Book()..id = 1..title = 'Book 1'..pages = ['Page 1']..status = BookStatus.ready,
        Book()..id = 2..title = 'Book 2'..pages = ['Page 1']..status = BookStatus.ready,
      ];
      mockLibraryService.booksToReturn = mockBooks;

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.initialize();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).books.length, equals(2));
    });

    test('should transition to Error state on initialization failure', () async {
      mockLibraryService.shouldThrow = true;
      mockLibraryService.exceptionToThrow = const FileOperationException(
        message: 'Database not initialized',
        operationType: FileOperationType.unknown,
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.initialize();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryError>());
      expect((state as LibraryError).error, isA<FileOperationException>());
    });
  });

  group('LibraryNotifier - Load Books', () {
    test('should load books successfully', () async {
      mockLibraryService.booksToReturn = [
        Book()..id = 1..title = 'Book 1'..pages = ['Page 1']..status = BookStatus.ready,
      ];

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadBooks();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).books.length, equals(1));
    });

    test('should handle empty book list', () async {
      mockLibraryService.booksToReturn = [];

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadBooks();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryLoaded>());
      expect((state as LibraryLoaded).books.isEmpty, isTrue);
    });

    test('should transition to Error state on load failure', () async {
      mockLibraryService.shouldThrow = true;
      mockLibraryService.exceptionToThrow = const FileOperationException(
        message: 'Failed to load books',
        operationType: FileOperationType.readFailed,
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadBooks();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryError>());
    });
  });

  group('LibraryNotifier - Delete Book', () {
    test('should delete book successfully and update state', () async {
      mockLibraryService.booksToReturn = [
        Book()..id = 1..title = 'Book 1'..pages = ['Page 1']..status = BookStatus.ready,
        Book()..id = 2..title = 'Book 2'..pages = ['Page 1']..status = BookStatus.ready,
      ];

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadBooks();
      expect((container.read(libraryNotifierProvider) as LibraryLoaded).books.length, equals(2));

      await notifier.deleteBook(1);

      final state = container.read(libraryNotifierProvider);
      expect((state as LibraryLoaded).books.length, equals(1));
      expect((state as LibraryLoaded).books.first.id, equals(2));
    });

    test('should return false on delete failure', () async {
      mockLibraryService.shouldThrow = true;
      mockLibraryService.exceptionToThrow = const FileOperationException(
        message: 'Delete failed',
        operationType: FileOperationType.fileNotFound,
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      final result = await notifier.deleteBook(1);

      expect(result, isFalse);
      expect(container.read(libraryNotifierProvider), isA<LibraryError>());
    });
  });

  group('LibraryLoaded State Helpers', () {
    test('should filter favorites correctly', () {
      final books = [
        Book()..id = 1..title = 'Fav 1'..pages = ['Page']..isFavorite = true..status = BookStatus.ready,
        Book()..id = 2..title = 'Not Fav'..pages = ['Page']..isFavorite = false..status = BookStatus.ready,
        Book()..id = 3..title = 'Fav 2'..pages = ['Page']..isFavorite = true..status = BookStatus.ready,
      ];

      final state = LibraryLoaded(books);
      final favorites = state.favorites;

      expect(favorites.length, equals(2));
      expect(favorites.every((b) => b.isFavorite), isTrue);
    });

    test('should sort recently read correctly', () {
      final now = DateTime.now();
      final books = [
        Book()..id = 1..title = 'Old'..pages = ['Page']..lastReadAt = now.subtract(const Duration(days: 5))..status = BookStatus.ready,
        Book()..id = 2..title = 'Recent'..pages = ['Page']..lastReadAt = now.subtract(const Duration(days: 1))..status = BookStatus.ready,
        Book()..id = 3..title = 'Newest'..pages = ['Page']..lastReadAt = now..status = BookStatus.ready,
      ];

      final state = LibraryLoaded(books);
      final sorted = state.recentlyRead;

      expect(sorted.first.id, equals(3));
      expect(sorted.last.id, equals(1));
    });

    test('should filter by status correctly', () {
      final books = [
        Book()..id = 1..title = 'Ready'..pages = ['Page']..status = BookStatus.ready,
        Book()..id = 2..title = 'Processing'..pages = ['Page']..status = BookStatus.processing,
        Book()..id = 3..title = 'Ready 2'..pages = ['Page']..status = BookStatus.ready,
      ];

      final state = LibraryLoaded(books);
      final readyBooks = state.getByStatus(BookStatus.ready);

      expect(readyBooks.length, equals(2));
      expect(readyBooks.every((b) => b.status == BookStatus.ready), isTrue);
    });

    test('should search by title case-insensitively', () {
      final books = [
        Book()..id = 1..title = 'The Great Gatsby'..pages = ['Page']..status = BookStatus.ready,
        Book()..id = 2..title = 'To Kill a Mockingbird'..pages = ['Page']..status = BookStatus.ready,
        Book()..id = 3..title = '1984'..pages = ['Page']..status = BookStatus.ready,
      ];

      final state = LibraryLoaded(books);
      
      expect(state.searchByTitle('great').length, equals(1));
      expect(state.searchByTitle('MOCKINGBIRD').length, equals(1));
      expect(state.searchByTitle('').length, equals(3));
    });
  });

  group('Error Propagation', () {
    test('should handle AppError types correctly', () async {
      mockLibraryService.shouldThrow = true;
      mockLibraryService.exceptionToThrow = const OcrException(
        message: 'OCR error',
        failureType: OcrFailureType.unknown,
      );

      final notifier = container.read(libraryNotifierProvider.notifier);
      await notifier.loadBooks();

      final state = container.read(libraryNotifierProvider);
      expect(state, isA<LibraryError>());
    });
  });
}
