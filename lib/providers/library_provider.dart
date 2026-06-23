// lib/providers/library_provider.dart
//
// Riverpod providers for document library management.
// Provides state management for the library screen with error handling.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/error/app_error.dart';
import '../data/models/book.dart';
import '../services/library/library_service.dart';

// ---------------------------------------------------------------------------
// Library Service Provider
// ---------------------------------------------------------------------------

/// Provider for the library service implementation.
/// Must be overridden in main.dart with concrete implementation.
final Provider<LibraryService> libraryServiceProvider = Provider<LibraryService>((ref) {
  throw AssertionError(
    'libraryServiceProvider has not been overridden in ProviderScope. '
    'See main.dart — pass your concrete LibraryServiceImpl.',
  );
});

// ---------------------------------------------------------------------------
// Library State
// ---------------------------------------------------------------------------

/// State holder for library operations.
sealed class LibraryState {
  const LibraryState();
}

/// Initial loading state.
final class LibraryLoading extends LibraryState {
  const LibraryLoading();
}

/// Library loaded successfully with list of books.
final class LibraryLoaded extends LibraryState {
  final List<Book> books;
  
  const LibraryLoaded(this.books);
  
  /// Get only favorite books
  List<Book> get favorites => books.where((b) => b.isFavorite).toList();
  
  /// Get recently read books (sorted by lastReadAt)
  List<Book> get recentlyRead => List<Book>.from(books)
    ..sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
  
  /// Get books by status
  List<Book> getByStatus(BookStatus status) {
    return books.where((b) => b.status == status).toList();
  }
  
  /// Search books by title
  List<Book> searchByTitle(String query) {
    if (query.trim().isEmpty) return books;
    final lowercaseQuery = query.toLowerCase();
    return books.where((b) => 
      b.title.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }
}

/// Error state when library operations fail.
final class LibraryError extends LibraryState {
  final AppError error;
  
  const LibraryError(this.error);
}

// ---------------------------------------------------------------------------
// Library Notifier
// ---------------------------------------------------------------------------

/// State notifier for managing library state and operations.
class LibraryNotifier extends StateNotifier<LibraryState> {
  LibraryNotifier({
    required LibraryService libraryService,
  }) : _libraryService = libraryService,
       super(const LibraryLoading());
  
  final LibraryService _libraryService;
  
  /// Initialize the library service and load all books.
  Future<void> initialize() async {
    try {
      await _libraryService.initialize();
      await loadBooks();
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'initialize_library'));
    }
  }
  
  /// Load all books from the database.
  Future<void> loadBooks() async {
    try {
      final books = await _libraryService.getAllBooks();
      state = LibraryLoaded(books);
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'load_books'));
    }
  }
  
  /// Save a new book to the library.
  Future<Book?> saveBook({
    required String title,
    required List<String> pages,
    required SourceType sourceType,
    String? filePath,
  }) async {
    try {
      final book = await _libraryService.saveBook(
        title: title,
        pages: pages,
        sourceType: sourceType,
        filePath: filePath,
      );
      
      // Update state with new book
      if (state is LibraryLoaded) {
        final currentBooks = List<Book>.from((state as LibraryLoaded).books);
        currentBooks.add(book);
        state = LibraryLoaded(currentBooks);
      }
      
      return book;
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'save_book'));
      return null;
    }
  }
  
  /// Delete a book from the library (soft delete).
  Future<bool> deleteBook(int bookId) async {
    try {
      await _libraryService.deleteBook(bookId);
      
      // Update state to remove deleted book
      if (state is LibraryLoaded) {
        final currentBooks = (state as LibraryLoaded).books
            .where((b) => b.id != bookId)
            .toList();
        state = LibraryLoaded(currentBooks);
      }
      
      return true;
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'delete_book'));
      return false;
    }
  }
  
  /// Update reading position for a book.
  Future<bool> updateReadingPosition({
    required int bookId,
    required int pageIndex,
    required int paragraphIndex,
  }) async {
    try {
      await _libraryService.updateReadingPosition(
        bookId: bookId,
        pageIndex: pageIndex,
        paragraphIndex: paragraphIndex,
      );
      return true;
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'update_position'));
      return false;
    }
  }
  
  /// Mark a book as favorite.
  Future<bool> toggleFavorite(int bookId) async {
    try {
      final book = await _libraryService.getBookById(bookId);
      if (book == null) {
        throw const FileOperationException(
          message: 'Book not found.',
          operationType: FileOperationType.fileNotFound,
        );
      }
      
      await _libraryService.updateBookStatus(bookId, book.status);
      book.isFavorite = !book.isFavorite;
      
      // Note: We need to add a method to update favorite status
      // For now, we'll just update the state locally
      if (state is LibraryLoaded) {
        final currentBooks = List<Book>.from((state as LibraryLoaded).books);
        final index = currentBooks.indexWhere((b) => b.id == bookId);
        if (index != -1) {
          currentBooks[index].isFavorite = !currentBooks[index].isFavorite;
          state = LibraryLoaded(currentBooks);
        }
      }
      
      return true;
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'toggle_favorite'));
      return false;
    }
  }
  
  /// Search in all books for text content.
  Future<List<SearchResult>> searchInBooks(String query) async {
    try {
      return await _libraryService.searchInBooks(query);
    } on AppError {
      rethrow;
    } catch (e) {
      state = LibraryError(FileOperationException.fromException(e, 'search'));
      return [];
    }
  }
  
  /// Retry after error.
  Future<void> retry() async {
    if (state is LibraryError) {
      await initialize();
    }
  }
}

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// The main library provider watched by UI components.
final StateNotifierProvider<LibraryNotifier, LibraryState> libraryNotifierProvider =
    StateNotifierProvider<LibraryNotifier, LibraryState>((ref) {
  return LibraryNotifier(
    libraryService: ref.watch(libraryServiceProvider),
  );
});
